function! luis#kind#history#import() abort
  return s:Kind
endfunction

function! s:action_open(candidate, context) abort
  if !has_key(a:candidate.user_data, 'history_name')
    throw 'luis(kind.history): No history chosen'
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
endfunction

function! s:action_open_x(candidate, context) abort
  if !has_key(a:candidate.user_data, 'history_name')
    throw 'luis(kind.history): No history chosen'
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
endfunction

function! s:action_delete(candidate, context) abort
  if !has_key(a:candidate.user_data, 'history_name')
  \  && !has_key(a:candidate.user_data, 'history_index')
    throw 'luis(kind.history): No history chosen'
  endif
  let history_name = a:candidate.user_data.history_name
  let history_index = a:candidate.user_data.history_index
  call histdel(history_name, history_index)
endfunction

let s:Kind = {
\   'name': 'history',
\   'action_table': {
\     'open': function('s:action_open'),
\     'open!': function('s:action_open_x'),
\     'delete': function('s:action_delete'),
\   },
\   'key_table': {
\     'd': 'delete',
\   },
\   'prototype': luis#kind#common#import(),
\ }
