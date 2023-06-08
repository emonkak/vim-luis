function! luis#kind#tag#import() abort
  return s:Kind
endfunction

function! s:action_open(candidate, context) abort
  return s:do_command('tag', a:candidate, a:context)
endfunction

function! s:action_open_x(candidate, context) abort
  return s:do_command('tag!', a:candidate, a:context)
endfunction

function! s:do_command(command, candidate, context) abort
  let v:errmsg = ''
  silent! execute a:command a:candidate.word
  if v:errmsg != ''
    return v:errmsg
  endif
  return 0
endfunction

let s:Kind = {
\   'name': 'tag',
\   'action_table': {
\     'open': function('s:action_open'),
\     'open!': function('s:action_open_x'),
\   },
\   'key_table': {},
\   'prototype': luis#kind#common#import(),
\ }
