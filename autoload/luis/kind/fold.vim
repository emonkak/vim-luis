function! s:action_open(kind, candidate) abort
  if !has_key(a:candidate.user_data, 'fold_lnum')
    return 'No fold chosen'
  endif
  call cursor(a:candidate.user_data.fold_lnum, 1)
  normal! zvzt
  return 0
endfunction

let g:luis#kind#fold#export = {
\   'name': 'fold',
\   'action_table': {
\     'open': function('s:action_open'),
\   },
\   'key_table': {},
\   'prototype': g:luis#kind#common#export,
\ }
