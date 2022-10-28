#!/bin/bash -eu

limit=$1
buffer="$("${@:2}")"
count=1

while read line
do
  echo "${buffer}" | fzf -f "$line" | head -n $limit | while read line
  do
    echo $count $line
  done
  count=$(( count + 1 ))
done
