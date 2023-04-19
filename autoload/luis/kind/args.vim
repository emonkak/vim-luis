function! s:action_argdelete(kind, candidate) abort
  let v:errmsg = ''
  silent! execute 'argdelete' fnameescape(a:candidate.word)
  return v:errmsg == '' ? 0 : v:errmsg
endfunction

let g:luis#kind#args#export = {
\   'name': 'args',
\   'action_table': {
\     'argdelete': function('s:action_argdelete'),
\   },
\   'key_table': {
\     'D': 'argdelete',
\   },
\   'prototype': g:luis#kind#buffer#export,
\ }
