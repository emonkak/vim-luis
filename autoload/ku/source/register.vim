" ku source: register
" Constants  "{{{1

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








" Module  "{{{1

let s:SOURCE_TEMPLATE = {
\   'name': 'register',
\   'kind': {
\     'action_table': {
\       'Put': function('ku#source#register#action_Put'),
\       'default': function('ku#source#register#action_put'),
\       'delete': function('ku#source#register#action_delete'),
\       'put': function('ku#source#register#action_put'),
\     },
\     'key_table': {
\       "\<C-d>": 'delete',
\       'P': 'Put',
\       'd': 'delete',
\       'p': 'put',
\     },
\     'prototype': g:ku#kind#common#module,
\   },
\   'matcher': g:ku#matcher#default,
\   'gather_candidates': function('ku#source#register#gather_candidates'),
\   'on_action': function('ku#source#default#on_action'),
\   'on_source_enter': function('ku#source#register#on_source_enter'),
\   'on_source_leave': function('ku#source#default#on_source_leave'),
\   'special_char_p': function('ku#source#default#special_char_p'),
\   'valid_for_acc_p': function('ku#source#default#valid_for_acc_p'),
\ }

function! ku#source#register#new() abort
  return extend({'_cached_candidates': []}, s:SOURCE_TEMPLATE, 'keep')
endfunction








" Interface  "{{{1
function! ku#source#register#gather_candidates(pattern) abort dict  "{{{2
  return self._cached_candidates
endfunction




function! ku#source#register#on_source_enter() abort dict  "{{{2
  let candidates = []
  for i in range(len(s:AVAILABLE_REGISTERS))
    let register = s:AVAILABLE_REGISTERS[i]
    let reginfo = getreginfo(register)
    if empty(reginfo) || empty(reginfo.regcontents)
      continue
    endif
    call add(candidates, {
    \   'word': register,
    \   'abbr': '"' . register . ' ' . reginfo.regcontents[0],
    \   'user_data': {
    \     'ku_register': register,
    \   },
    \   'ku__sort_priority': i,
    \ })
  endfor
  let self._cached_candidates = candidates
endfunction








" Actions  "{{{1
function! ku#source#register#action_Put(candidate) abort  "{{{2
  if !has_key(a:candidate.user_data, 'ku_register')
    return 'No register found'
  endif
  execute 'normal! "' . a:candidate.user_data.ku_register . 'P'
  return 0
endfunction





function! ku#source#register#action_delete(candidate) abort  "{{{2
  if !has_key(a:candidate.user_data, 'ku_register')
    return 'No register found'
  endif
  call setreg(a:candidate.user_data.ku_register, '')
  return 0
endfunction





function! ku#source#register#action_put(candidate) abort  "{{{2
  if !has_key(a:candidate.user_data, 'ku_register')
    return 'No register found'
  endif
  execute 'normal! "' . a:candidate.user_data.ku_register . 'p'
  return 0
endfunction








" __END__  "{{{1
" vim: foldmethod=marker
