function! s:action_Put(kind, candidate) abort
  if !has_key(a:candidate.user_data, 'register_name')
    return 'No register found'
  endif
  execute 'normal! "' . a:candidate.user_data.register_name . 'P'
  return 0
endfunction

function! s:action_delete(kind, candidate) abort
  if !has_key(a:candidate.user_data, 'register_name')
    return 'No register found'
  endif
  call setreg(a:candidate.user_data.register_name, '')
  return 0
endfunction

function! s:action_put(kind, candidate) abort
  if !has_key(a:candidate.user_data, 'register_name')
    return 'No register found'
  endif
  execute 'normal! "' . a:candidate.user_data.register_name . 'p'
  return 0
endfunction

let g:luis#kind#register#export = {
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
\   'prototype': g:luis#kind#common#export,
\ }
