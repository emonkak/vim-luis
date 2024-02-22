function! luis#kind#colorscheme#import() abort
  return s:Kind
endfunction

function! s:action_open(candidate, context) abort
  execute 'colorscheme' a:candidate.word
endfunction

let s:Kind = {
\   'name': 'colorscheme',
\   'action_table': {
\     'open': function('s:action_open'),
\   },
\   'key_table': {},
\   'prototype': luis#kind#common#import(),
\ }
