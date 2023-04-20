#!/bin/env bash

set -o errexit -o nounset

if [[ "${TRACE-0}" == "1" ]]
then
    set -o xtrace
fi

limit=$1
command_output="$("${@:2}")"

while read -r sequence pattern
do
  while read -r line
  do
    echo "${sequence}" "${line}"
  done < <(fzf -f "${pattern}" <<< "${command_output}" | head -n ${limit})
  echo ${sequence}
done
