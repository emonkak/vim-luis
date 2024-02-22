function! luis#kind#text#import() abort
  return s:Kind
endfunction

function! s:action_open(candidate, context) abort
  execute 'normal!' "i\<C-r>=a:candidate.word\<CR>"
endfunction

function! s:action_open_x(candidate, context) abort
  execute 'normal!' "a\<C-r>=a:candidate.word\<CR>"
endfunction

let s:Kind = {
\   'name': 'text',
\   'action_table': {
\     'open': function('s:action_open'),
\     'open!': function('s:action_open_x'),
\   },
\   'key_table': {},
\   'prototype': luis#kind#common#import(),
\ }
