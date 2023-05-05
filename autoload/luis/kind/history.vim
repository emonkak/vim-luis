function! s:action_open(kind, candidate) abort
  if !has_key(a:candidate.user_data, 'history_name')
    return 'No history chosen'
  endif
  let history_name = a:candidate.user_data.history_name
  if history_name ==# 'cmd'
    call feedkeys(':' . a:candidate.word, 'n')
  elseif history_name ==# 'search'
    call feedkeys('/' . a:candidate.word, 'n')
  elseif history_name ==# 'expr'
    call feedkeys("i\<C-r>=" . a:candidate.word, 'n')
  elseif history_name ==# 'input'
    execute 'normal!' "i\<C-r>=a:candidate.word\<CR>"
  endif
  return 0
endfunction

function! s:action_open_x(kind, candidate) abort
  if !has_key(a:candidate.user_data, 'history_name')
    return 'No history chosen'
  endif
  let history_name = a:candidate.user_data.history_name
  if history_name ==# 'cmd'
    call feedkeys(':' . a:candidate.word, 'n')
  elseif history_name ==# 'search'
    call feedkeys('?' . a:candidate.word, 'n')
  elseif history_name ==# 'expr'
    call feedkeys("a\<C-r>=" . a:candidate.word, 'n')
  elseif history_name ==# 'input'
    execute 'normal!' "a\<C-r>=a:candidate.word\<CR>"
  endif
  return 0
endfunction

function! s:action_delete(kind, candidate) abort
  if !has_key(a:candidate.user_data, 'history_name')
  \  && !has_key(a:candidate.user_data, 'history_index')
    return 'No history chosen'
  endif
  let history_name = a:candidate.user_data.history_name
  let history_index = a:candidate.user_data.history_index
  call histdel(history_name, history_index)
  return 0
endfunction

let g:luis#kind#history#export = {
\   'name': 'history',
\   'action_table': {
\     'open': function('s:action_open'),
\     'open!': function('s:action_open_x'),
\     'delete': function('s:action_delete'),
\   },
\   'key_table': {
\     'd': 'delete',
\   },
\   'prototype': g:luis#kind#common#export,
\ }
