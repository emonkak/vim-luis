function! luis#kind#mark#import() abort
  return s:Kind
endfunction

function! s:action_delete(candidate, context) abort
  if !has_key(a:candidate.user_data, 'mark_name')
    throw 'luis(kind.mark): No mark chosen'
  endif
  execute 'delmarks' a:candidate.user_data.mark_name
endfunction

function! s:action_open(candidate, context) abort
  if !has_key(a:candidate.user_data, 'mark_name')
    throw 'luis(kind.mark): No mark chosen'
  endif
  execute 'normal!' '`' . a:candidate.user_data.mark_name
endfunction

let s:Kind = {
\   'name': 'mark',
\   'action_table': {
\     'open': function('s:action_open'),
\     'delete': function('s:action_delete'),
\   },
\   'key_table': {
\     "\<C-d>": 'delete',
\     'd': 'delete',
\   },
\   'prototype': luis#kind#common#import(),
\ }
