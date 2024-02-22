function! luis#kind#tag#import() abort
  return s:Kind
endfunction

function! s:action_open(candidate, context) abort
  execute 'tag' a:candidate.word
endfunction

function! s:action_open_x(candidate, context) abort
  execute 'tag!' a:candidate.word
endfunction

let s:Kind = {
\   'name': 'tag',
\   'action_table': {
\     'open': function('s:action_open'),
\     'open!': function('s:action_open_x'),
\   },
\   'key_table': {},
\   'prototype': luis#kind#common#import(),
\ }
