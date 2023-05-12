function! luis#kind#register#import() abort
  return s:Kind
endfunction

function! s:action_Put(candidate, context) abort
  if !has_key(a:candidate.user_data, 'register_name')
    return 'No register chosen'
  endif
  execute 'normal! "' . a:candidate.user_data.register_name . 'P'
  return 0
endfunction

function! s:action_delete(candidate, context) abort
  if !has_key(a:candidate.user_data, 'register_name')
    return 'No register chosen'
  endif
  call setreg(a:candidate.user_data.register_name, [])
  return 0
endfunction

function! s:action_put(candidate, context) abort
  if !has_key(a:candidate.user_data, 'register_name')
    return 'No register chosen'
  endif
  execute 'normal! "' . a:candidate.user_data.register_name . 'p'
  return 0
endfunction

let s:Kind = {
\   'name': 'register',
\   'action_table': {
\     'Put': function('s:action_Put'),
\     'default': function('s:action_put'),
\     'delete': function('s:action_delete'),
\     'put': function('s:action_put'),
\   },
\   'key_table': {
\     "\<C-d>": 'delete',
\     'P': 'Put',
\     'd': 'delete',
\     'p': 'put',
\   },
\   'prototype': luis#kind#common#import(),
\ }
