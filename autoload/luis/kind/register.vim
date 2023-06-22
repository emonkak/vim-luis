function! luis#kind#register#import() abort
  return s:Kind
endfunction

function! s:action_delete(candidate, context) abort
  if !has_key(a:candidate.user_data, 'register_name')
    return 'No register chosen'
  endif
  call setreg(a:candidate.user_data.register_name, [])
  return 0
endfunction

function! s:action_open(candidate, context) abort
  if !has_key(a:candidate.user_data, 'register_name')
    return 'No register chosen'
  endif
  execute 'normal! "' . a:candidate.user_data.register_name . 'p'
  return 0
endfunction

function! s:action_open_x(candidate, context) abort
  if !has_key(a:candidate.user_data, 'register_name')
    return 'No register chosen'
  endif
  execute 'normal! "' . a:candidate.user_data.register_name . 'P'
  return 0
endfunction

let s:Kind = {
\   'name': 'register',
\   'action_table': {
\     'delete': function('s:action_delete'),
\     'open': function('s:action_open'),
\     'open!': function('s:action_open_x'),
\   },
\   'key_table': {
\     'd': 'delete',
\   },
\   'prototype': luis#kind#common#import(),
\ }
