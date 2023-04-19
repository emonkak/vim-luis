function! s:action_delete(kind, candidate) abort
  if !has_key(a:candidate.user_data, 'mark_name')
    return 'No mark found'
  endif
  execute 'delmarks' a:candidate.user_data.mark_name
  return 0
endfunction

function! s:action_open(kind, candidate) abort
  if !has_key(a:candidate.user_data, 'mark_name')
    return 'No mark found'
  endif
  execute 'normal!' '`' . a:candidate.mark_name
  return 0
endfunction

let g:luis#kind#mark#export = {
\   'name': 'mark',
\   'action_table': {
\     'open': function('s:action_open'),
\     'delete': function('s:action_delete'),
\   },
\   'key_table': {
\     "\<C-d>": 'delete',
\     'd': 'delete',
\   },
\   'prototype': g:luis#kind#common#export,
\ }
