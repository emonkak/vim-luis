function! s:action_open(kind, candidate) abort
  execute 'normal!' "i\<C-r>=a:candidate.word\<CR>\<Esc>"
  return 0
endfunction

function! s:action_put(kind, candidate) abort
  put =a:candidate.word
  return 0
endfunction

function! s:action_put_x(kind, candidate) abort
  put! =a:candidate.word
  return 0
endfunction

let g:luis#kind#text#export = {
\   'name': 'text',
\   'action_table': {
\     'open': function('s:action_open'),
\     'put!': function('s:action_put_x'),
\     'put': function('s:action_put'),
\   },
\   'key_table': {
\     'P': 'put!',
\     'p': 'put',
\   },
\   'prototype': g:luis#kind#common#export,
\ }

