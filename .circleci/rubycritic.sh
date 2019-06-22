#!/bin/sh

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
rubycritic -t 100 --mode-ci $BASE_BRANCH --no-browser -p $REPORT_PATH ./app ./lib


base_score=`head -n 1 $REPORT_PATH/compare/build_details.txt | awk '{print $5}'`
feature_score=`head -n 2 $REPORT_PATH/compare/build_details.txt | tail -n 1 | awk '{print $5}'`
compare_score=`echo $feature_score | awk '{print $1-'$base_score'}'`

if [ "$compare_score" = "0" ]; then
  mark="±0"
elif [ `echo $compare_score | cut -c 1` = "-" ]; then
  mark="${compare_score} :arrow_down:"
else
  mark="+${compare_score} :arrow_up:"
fi

report_url="https://circle-artifacts.com/gh/$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME/$CIRCLE_BUILD_NUM/artifacts/0/$REPORT_PATH/compare/$BASE_BRANCH/compare/$CIRCLE_BRANCH/overview.html"

body="{\"body\": \"**Rubycritic** current score: <a href='$report_url' target='_blank'>$feature_score</a> ($BASE_BRANCH: $base_score, $mark)\"}"

export PR_NUMBER=`echo $CI_PULL_REQUEST | awk -F/ '{print $(NF-0)}'`
curl -XPOST \
  -H "Authorization: token $GITHUB_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d "$body" \
  https://api.github.com/repos/$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME/issues/$PR_NUMBER/comments

