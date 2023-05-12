function! luis#kind#colorscheme#import() abort
  return s:Kind
endfunction

function! s:action_open(candidate, context) abort
  try
    execute 'colorscheme' a:candidate.word
  catch
    return v:exception
  endtry
  return 0
endfunction

let s:Kind = {
\   'name': 'colorscheme',
\   'action_table': {
\     'open': function('s:action_open'),
\   },
\   'key_table': {},
\   'prototype': luis#kind#common#import(),
\ }
