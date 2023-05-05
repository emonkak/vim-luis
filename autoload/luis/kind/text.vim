function! s:action_open(kind, candidate) abort
  execute 'normal!' "i\<C-r>=a:candidate.word\<CR>"
  return 0
endfunction

function! s:action_open_x(kind, candidate) abort
  execute 'normal!' "a\<C-r>=a:candidate.word\<CR>"
  return 0
endfunction

let g:luis#kind#text#export = {
\   'name': 'text',
\   'action_table': {
\     'open': function('s:action_open'),
\     'open!': function('s:action_open_x'),
\   },
\   'key_table': {},
\   'prototype': g:luis#kind#common#export,
\ }
