#!/bin/env bash

set -o errexit -o nounset

source="$("${@}")"

while read -r sequence pattern
do
  while read -r line
  do
    if [[ "${line}" == *"${pattern}"* ]]
    then
      echo "${sequence}" "${line}"
    fi
  done <<< "${source}"
  echo "${sequence}"
done
