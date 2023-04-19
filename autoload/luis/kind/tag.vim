function! s:action_open(kind, candidate) abort
  execute 'tag' a:candidate.word
  return 0
endfunction

function! s:action_open_x(kind, candidate) abort
  execute 'tag!' a:candidate.word
  return 0
endfunction

let g:luis#kind#tag#export = {
\   'name': 'tag',
\   'action_table': {
\     'open': function('s:action_open'),
\     'open_x': function('s:action_open_x'),
\   },
\   'key_table': {},
\   'prototype': g:luis#kind#common#export,
\ }
