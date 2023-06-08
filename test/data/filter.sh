#!/bin/env bash

set -o errexit -o nounset

output="$("${@}")"

while read -r sequence pattern
do
  while read -r line
  do
    if [[ "${line}" == *"${pattern}"* ]]
    then
      echo "${sequence}" "${line}"
    fi
  done <<< "${output}"
  echo "${sequence}"
done
