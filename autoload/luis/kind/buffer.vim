function! luis#kind#buffer#import() abort
  return s:Kind
endfunction

function! s:action_delete(candidate, context) abort
  call s:do_command('bdelete', a:candidate)
endfunction

function! s:action_delete_x(candidate, context) abort
  call s:do_command('bdelete!', a:candidate)
endfunction

function! s:action_open(candidate, context) abort
  call s:do_command('buffer', a:candidate)
endfunction

function! s:action_open_x(candidate, context) abort
  call s:do_command('buffer!', a:candidate)
endfunction

function! s:action_unload(candidate, context) abort
  call s:do_command('bunload', a:candidate)
endfunction

function! s:action_unload_x(candidate, context) abort
  call s:do_command('bunload!', a:candidate)
endfunction

function! s:action_wipeout(candidate, context) abort
  call s:do_command('bwipeout', a:candidate)
endfunction

function! s:action_wipeout_x(candidate, context) abort
  call s:do_command('bwipeout!', a:candidate)
endfunction

function! s:do_command(command, candidate) abort
  let bufnr = has_key(a:candidate.user_data, 'buffer_nr')
  \         ? a:candidate.user_data.buffer_nr
  \         : bufnr(fnameescape(a:candidate.word))
  if bufnr < 1
    throw 'luis(kind.buffer): There is no corresponding buffer to candidate: '
    \     . string(a:candidate.word)
  endif
  execute bufnr a:command
  if has_key(a:candidate.user_data, 'buffer_cursor')
    call cursor(a:candidate.user_data.buffer_cursor)
    normal! zvzt
  endif
endfunction

let s:Kind = {
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
\   'prototype': luis#kind#common#import(),
\ }
