function! s:action_argdelete(kind, candidate) abort
  try
    execute 'argdelete' fnameescape(a:candidate.word)
  catch
    return v:exception
  endtry
  return 0
endfunction

let g:luis#kind#args#export = {
\   'name': 'args',
\   'action_table': {
\     'argdelete': function('s:action_argdelete'),
\   },
\   'key_table': {
\     'R': 'argdelete',
\   },
\   'prototype': g:luis#kind#buffer#export,
\ }
