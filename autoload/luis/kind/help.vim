function! luis#kind#help#import() abort
  return s:Kind
endfunction

function! s:action_open(candidate, context) abort
  call s:open_help(a:candidate.word, '')
endfunction

function! s:action_open_x(candidate, context) abort
  call s:open_help(a:candidate.word, '!')
endfunction

function! s:open_help(subject, bang) abort
  let command = 'edit' . a:bang
  execute command '`=&helpfile`'
  set buftype=help
  execute 'help' a:subject
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
