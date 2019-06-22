#!/bin/bash

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

compare_score () {
  local base_score=`head -n 1 $REPORT_PATH/compare/build_details.txt | awk '{print $5}'`
  local feature_score=`head -n 2 $REPORT_PATH/compare/build_details.txt | tail -n 1 | awk '{print $5}'`
  local compare_score=`echo $feature_score | awk '{print $1-'$base_score'}'`

  if [ "$compare_score" = "0" ]; then
    local mark="±0"
  elif [ `echo $compare_score | cut -c 1` = "-" ]; then
    local mark="${compare_score} :arrow_down:"
  else
    local mark="+${compare_score} :arrow_up:"
  fi

  echo "$base_score" "$feature_score" "$mark"
}

gem install -N rubycritic
mkdir -p $REPORT_PATH

############ branch score
rubycritic -t 100 --mode-ci $BASE_BRANCH --no-browser -p $REPORT_PATH ./app ./lib
result=(`compare_score`)
report_url="https://circle-artifacts.com/gh/$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME/$CIRCLE_BUILD_NUM/artifacts/0/$REPORT_PATH/compare/$BASE_BRANCH/compare/$CIRCLE_BRANCH/overview.html"

body="**Rubycritic** current score: <a href='$report_url' target='_blank'>${result[1]}</a> ($BASE_BRANCH: ${result[0]}, ${result[2]}${result[3]})"
body=$body"<details><summary>more details</summary>\n\n"

############ add files score
add_file_section=()
for file in `git diff --name-only --diff-filter=A origin/$BASE_BRANCH | grep \.rb`
do
  score=`rubycritic --no-browser $file | grep Score | cut -d : -f 2`
  add_file_section+=("- $file $score")
done
[ ${#add_file_section[@]} -ne 0 ] && body=$body"## add files\n"$(IFS=$'\n'; echo "${add_file_section[*]}")"\n"

body=$body"</details>"

export PR_NUMBER=`echo $CI_PULL_REQUEST | awk -F/ '{print $(NF-0)}'`
curl -XPOST \
  -H "Authorization: token $GITHUB_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"body\": \"$body\"}" \
  https://api.github.com/repos/$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME/issues/$PR_NUMBER/comments

