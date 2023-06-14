function! luis#kind#help#import() abort
  return s:Kind
endfunction

function! s:action_open(candidate, context) abort
  return s:open_help(a:candidate.word, '')
endfunction

function! s:action_open_x(candidate, context) abort
  return s:open_help(a:candidate.word, '!')
endfunction

function! s:open_help(subject, bang) abort
  let command = 'edit' . a:bang
  let v:errmsg = ''
  silent! execute command '`=&helpfile`'
  if v:errmsg != ''
    return v:errmsg
  endif
  set buftype=help
  silent! execute 'help' a:subject
  if v:errmsg != ''
    return v:errmsg
  endif
  return 0
endfunction

let s:Kind = {
\   'name': 'help',
\   'action_table': {
\     'open': function('s:action_open'),
\     'open_x': function('s:action_open_x'),
\   },
\   'key_table': {},
\   'prototype': luis#kind#common#import(),
\ }
