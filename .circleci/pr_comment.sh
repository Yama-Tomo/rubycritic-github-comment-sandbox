#!/bin/sh

master_score=`head -n 1 $REPORT_PATH/compare/build_details.txt | awk '{print $5}'`
feature_score=`head -n 2 $REPORT_PATH/compare/build_details.txt | tail -n 1 | awk '{print $5}'`
compare_score=`echo $feature_score | awk '{print $1-'$master_score'}'`

if [ "$compare_score" = "0" ]; then
  mark="±0"
elif [ `echo $compare_score | cut -c 1` = "-" ]; then
  mark="${compare_score} :arrow_down:"
else
  mark="+${compare_score} :arrow_up:"
fi

report_url="https://circle-artifacts.com/gh/$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME/$CIRCLE_BUILD_NUM/artifacts/0/$REPORT_PATH/compare/master/compare/$CIRCLE_BRANCH/overview.html"

body="{\"body\": \"**Current score**: [$feature_score]($report_url){:target='_blank'} (master: $master_score, $mark)\"}"

curl -XPOST \
  -H "Authorization: token $GITHUB_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d "$body" \
  https://api.github.com/repos/$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME/issues/$PR_NUMBER/comments

