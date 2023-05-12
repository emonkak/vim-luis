function! luis#kind#args#import() abort
  return s:Kind
endfunction

function! s:action_argdelete(candidate, context) abort
  try
    execute 'argdelete' fnameescape(a:candidate.word)
  catch
    return v:exception
  endtry
  return 0
endfunction

let s:Kind = {
\   'name': 'args',
\   'action_table': {
\     'argdelete': function('s:action_argdelete'),
\   },
\   'key_table': {
\     'R': 'argdelete',
\   },
\   'prototype': luis#kind#buffer#import(),
\ }
