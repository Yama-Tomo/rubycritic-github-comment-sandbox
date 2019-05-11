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

export PR_NUMBER=`echo $CI_PULL_REQUEST | awk -F/ '{print $(NF-0)}'`
gem install -N rubycritic

mkdir -p $REPORT_PATH
rubycritic -t 100 --mode-ci $BASE_BRANCH --no-browser -p $REPORT_PATH ./app ./lib

$(cd $(dirname $0) && pwd)/pr_comment.sh

