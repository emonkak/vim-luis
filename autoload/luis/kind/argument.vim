function! luis#kind#argument#import() abort
  return s:Kind
endfunction

function! s:action_open(candidate, context) abort
  return s:do_command('argument', a:candidate)
endfunction

function! s:action_argdelete(candidate, context) abort
  return s:do_command('argdelete', a:candidate)
endfunction

function! s:do_command(command, candidate) abort
  if !has_key(a:candidate.user_data, 'argument_index')
    return 'No argument chosen'
  endif
  let v:errmsg = ''
  silent! execute (a:candidate.user_data.argument_index + 1) a:command
  if v:errmsg != ''
    return v:errmsg
  endif
  return 0
endfunction

let s:Kind = {
\   'name': 'argument',
\   'action_table': {
\     'open': function('s:action_open'),
\     'argdelete': function('s:action_argdelete'),
\   },
\   'key_table': {
\     'd': 'argdelete',
\   },
\   'prototype': luis#kind#common#import(),
\ }
