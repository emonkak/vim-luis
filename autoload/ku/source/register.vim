let s:AVAILABLE_REGISTERS = '"'
\                         . '0123456789'
\                         . '-'
\                         . 'abcdefghijklmnopqrstuvwxyz'
\                         . 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
\                         . ':.%'
\                         . '#'
\                         . '='
\                         . '*+'
\                         . '/'

function! ku#source#register#new() abort
  let source = copy(s:Source)
  let source._cached_candidates = []
  return source
endfunction

function! s:action_Put(candidate) abort
  execute 'normal! "' . a:candidate.user_data.ku_register . 'P'
  return 0
endfunction

function! s:action_delete(candidate) abort
  call setreg(a:candidate.user_data.ku_register, '')
  return 0
endfunction

function! s:action_put(candidate) abort
  execute 'normal! "' . a:candidate.user_data.ku_register . 'p'
  return 0
endfunction

let s:Source = {
\   'name': 'register',
\   'default_kind': {
\     'action_table': {
\       'Put': function('s:action_Put'),
\       'default': function('s:action_put'),
\       'delete': function('s:action_delete'),
\       'put': function('s:action_put'),
\     },
\     'key_table': {
\       "\<C-d>": 'delete',
\       'P': 'Put',
\       'd': 'delete',
\       'p': 'put',
\     },
\     'prototype': g:ku#kind#common#export,
\   },
\   'matcher': g:ku#matcher#default,
\ }

function! s:Source.gather_candidates(pattern) abort dict
  return self._cached_candidates
endfunction

function! s:Source.on_source_enter() abort dict
  let candidates = []
  for i in range(len(s:AVAILABLE_REGISTERS))
    let register = s:AVAILABLE_REGISTERS[i]
    let reginfo = getreginfo(register)
    if empty(reginfo) || empty(reginfo.regcontents)
      continue
    endif
    call add(candidates, {
    \   'word': reginfo.regcontents[0],
    \   'menu': 'register ' . register,
    \   'dup': 1,
    \   'user_data': {
    \     'ku_register': register,
    \   },
    \   'ku__sort_priority': i,
    \ })
  endfor
  let self._cached_candidates = candidates
endfunction
