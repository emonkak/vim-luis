function! luis#kind#fold#import() abort
  return s:Kind
endfunction

function! s:action_open(candidate, context) abort
  if !has_key(a:candidate.user_data, 'fold_lnum')
    return 'No fold chosen'
  endif
  call cursor(a:candidate.user_data.fold_lnum, 1)
  normal! zvzt
  return 0
endfunction

let s:Kind = {
\   'name': 'fold',
\   'action_table': {
\     'open': function('s:action_open'),
\   },
\   'key_table': {},
\   'prototype': luis#kind#common#import(),
\ }
