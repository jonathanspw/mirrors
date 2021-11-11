#!/bin/bash

printenv

if [[ -z "${CIRCLE_PULL_REQUEST}" ]];
then
	echo "This is not a pull request, no PHPCS needed."
	exit 0
else
	echo "This is a pull request, continuing"
fi

regexp="[[:digit:]]\+$"
PR_NUMBER=`echo $CIRCLE_PULL_REQUEST | grep -o $regexp`

url="https://api.github.com/repos/$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME/pulls/$PR_NUMBER"

target_branch=$(curl -s -X GET -G \
$url \
-d access_token=$GITHUB_TOKEN | jq '.base.ref' | tr -d '"')

echo "Resetting $target_branch to where the remote version is..."
git checkout -q $target_branch

git reset --hard -q origin/$target_branch

git checkout -q $CIRCLE_BRANCH

echo "Getting list of changed files..."
changed_files=$(git diff --name-only $target_branch..$CIRCLE_BRANCH -- '*.php')
echo "$changed_files"

if [[ -z $changed_files ]]
then
	echo "There are no files to check."
	exit 0
fi