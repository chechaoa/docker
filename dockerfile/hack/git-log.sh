#!/bin/bash

set -e

git diff -a --name-only HEAD~1 -- . 
export git_log=$(git diff -a --name-only HEAD~1 -- . |grep -E '^(release|library)' | grep -Ev README.md$)
[ -z "$git_log" ] && echo "Exit:git_log return empty,no need to process" >&2 && exit 0
echo "$git_log" | while read line
do
  echo "$line"
  parameter=$(echo "$line" |sed -E 's#(.*/)(.*)?/Dockerfile$#\1\2#g' | sed -E 's#(.*)/(.*)#\1:\2#')
  echo "$parameter"
  bash hack/docker-build.sh -i "cargo.caicloud.xyz/$parameter" --push 
done
