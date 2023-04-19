function! s:action_delete(kind, candidate) abort
  return s:do_command('bdelete', a:candidate)
endfunction

function! s:action_delete_x(kind, candidate) abort
  return s:do_command('bdelete!', a:candidate)
endfunction

function! s:action_open(kind, candidate) abort
  return s:do_command('buffer', a:candidate)
endfunction

function! s:action_open_x(kind, candidate) abort
  return s:do_command('buffer!', a:candidate)
endfunction

function! s:action_unload(kind, candidate) abort
  return s:do_command('bunload', a:candidate)
endfunction

function! s:action_unload_x(kind, candidate) abort
  return s:do_command('bunload!', a:candidate)
endfunction

function! s:action_wipeout(kind, candidate) abort
  return s:do_command('bwipeout', a:candidate)
endfunction

function! s:action_wipeout_x(kind, candidate) abort
  return s:do_command('bwipeout!', a:candidate)
endfunction

function! s:do_command(command, candidate) abort
  if has_key(a:candidate.user_data, 'buffer_nr')
    let bufnr = a:candidate.user_data.buffer_nr
  else
    let bufnr = bufnr(fnameescape(a:candidate.word))
    if bufnr < 1 
      return 'There is no corresponding buffer to candidate: '
      \      . string(a:candidate.word)
    endif
  endif
  let v:errmsg = ''
  execute bufnr a:command
  if v:errmsg != ''
    return v:errmsg
  endif
  if has_key(a:candidate.user_data, 'buffer_pos')
    call cursor(a:candidate.user_data.buffer_pos)
  endif
  return 0
endfunction

let g:luis#kind#buffer#export = {
\   'name': 'buffer',
\   'action_table': {
\     'delete': function('s:action_delete'),
\     'delete!': function('s:action_delete_x'),
\     'open!': function('s:action_open_x'),
\     'open': function('s:action_open'),
\     'unload': function('s:action_unload'),
\     'unload!': function('s:action_unload_x'),
\     'wipeout': function('s:action_wipeout'),
\     'wipeout!': function('s:action_wipeout_x'),
\   },
\   'key_table': {
\     'D': 'delete!',
\     'U': 'unload!',
\     'W': 'wipeout!',
\     'd': 'delete',
\     'u': 'unload',
\     'w': 'wipeout',
\   },
\   'prototype': g:luis#kind#common#export,
\ }
