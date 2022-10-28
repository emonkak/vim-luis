#!/bin/bash -eu

limit=$1
source="$("${@:2}")"
sequence=1

while read line
do
  echo "${source}" | fzf -f "$line" | head -n $limit | while read body
  do
    echo $sequence $body
  done
  echo $sequence
  sequence=$(( sequence + 1 ))
done
