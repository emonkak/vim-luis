let g:ku#kind#buffer#export = {
\   'action_table': {
\     'delete': function('ku#kind#buffer#action_delete'),
\     'delete!': function('ku#kind#buffer#action_delete_x'),
\     'open!': function('ku#kind#buffer#action_open_x'),
\     'open': function('ku#kind#buffer#action_open'),
\     'unload': function('ku#kind#buffer#action_unload'),
\     'unload!': function('ku#kind#buffer#action_unload_x'),
\     'wipeout': function('ku#kind#buffer#action_wipeout'),
\     'wipeout!': function('ku#kind#buffer#action_wipeout_x'),
\   },
\   'key_table': {
\     'D': 'delete!',
\     'U': 'unload!',
\     'W': 'wipeout!',
\     'd': 'delete',
\     'u': 'unload',
\     'w': 'wipeout',
\   },
\   'prototype': g:ku#kind#common#export,
\ }

function! ku#kind#buffer#action_delete(candidate) abort
  return s:do_command('bdelete', a:candidate)
endfunction

function! ku#kind#buffer#action_delete_x(candidate) abort
  return s:do_command('bdelete!', a:candidate)
endfunction

function! ku#kind#buffer#action_open(candidate) abort
  return s:do_command('buffer', a:candidate)
endfunction

function! ku#kind#buffer#action_open_x(candidate) abort
  return s:do_command('buffer!', a:candidate)
endfunction

function! ku#kind#buffer#action_unload(candidate) abort
  return s:do_command('bunload', a:candidate)
endfunction

function! ku#kind#buffer#action_unload_x(candidate) abort
  return s:do_command('bunload!', a:candidate)
endfunction

function! ku#kind#buffer#action_wipeout(candidate) abort
  return s:do_command('bwipeout', a:candidate)
endfunction

function! ku#kind#buffer#action_wipeout_x(candidate) abort
  return s:do_command('bwipeout!', a:candidate)
endfunction

function! s:bufnr_from_candidate(candidate) abort
  if has_key(a:candidate.user_data, 'ku_buffer_nr')
    return a:candidate.user_data.ku_buffer_nr
  else
    let bufnr = bufnr(fnameescape(a:candidate.word))
    if 1 <= bufnr
      return bufnr
    else
      return 'There is no corresponding buffer to candidate: '
      \      . string(a:candidate.word)
    endif
  endif
endfunction

function! s:do_command(command, candidate) abort
  let bufnr = s:bufnr_from_candidate(a:candidate)
  if type(bufnr) != v:t_number
    return bufnr
  endif
  let v:errmsg = ''
  execute bufnr a:command
  if v:errmsg != ''
    return v:errmsg
  endif
  if has_key(a:candidate.user_data, 'ku_cursor')
    call cursor(a:candidate.user_data.ku_cursor)
  endif
  return 0
endfunction
