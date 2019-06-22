#!/bin/bash

current=$(cd $(dirname $0);pwd)
source $current/rubycritic-functions

if [ "$CI_PULL_REQUEST" = "" ]; then
  echo 'skip: PR not create yet'
  exit 0
fi

git fetch origin

compare="origin/$BASE_BRANCH"
if [ "$BEFORE_REVISION" != "" -a "$AFTER_REVISION" != "" ]; then
  compare="$BEFORE_REVISION..$AFTER_REVISION"
fi

if [ `git diff --name-only $compare | grep -c \.rb` -eq 0 ]; then
  echo 'skip: not change ruby files'
  exit 0
fi

# NOTE: 比較する元のブランチを最新状態にする
git checkout $BASE_BRANCH
git reset --hard origin/$BASE_BRANCH
git checkout $CIRCLE_BRANCH

gem install -N rubycritic
mkdir -p $REPORT_PATH

report_url="https://circle-artifacts.com/gh/$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME/$CIRCLE_BUILD_NUM/"\
"artifacts/0/$REPORT_PATH/compare/$BASE_BRANCH/compare/$CIRCLE_BRANCH/overview.html"

body=`branch_score_section $BASE_BRANCH $REPORT_PATH "./app ./lib" $report_url`
add_files_score_section=`add_files_score_section $BASE_BRANCH`
change_files_score_section=`change_files_score_section $BASE_BRANCH`

if [ "$add_files_score_section" != "" -o "$change_files_score_section" != "" ]; then
  body=`cat << DOC
$body
<details>
  <summary>more details</summary>\n
  \n
$add_files_score_section
$change_files_score_section
</details>  
DOC
`
fi

pr_number=`echo $CI_PULL_REQUEST | awk -F/ '{print $(NF-0)}'`
curl -XPOST \
  -H "Authorization: token $GITHUB_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"body\": \"$body\"}" \
  https://api.github.com/repos/$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME/issues/$pr_number/comments

