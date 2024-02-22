function! luis#kind#quickfix#import() abort
  return s:Kind
endfunction

function! s:action_open(candidate, context) abort
  call s:do_open('cc', a:candidate)
endfunction

function! s:action_open_x(candidate, context) abort
  call s:do_open('cc!', a:candidate)
endfunction

function! s:do_open(command, candidate) abort
  if !has_key(a:candidate.user_data, 'quickfix_nr')
    throw 'luis(kind.quickfix): No error chosen'
  endif
  let original_switchbuf = &switchbuf
  let &switchbuf = ''
  try
    execute a:command a:candidate.user_data.quickfix_nr
  finally
    let &switchbuf = original_switchbuf
  endtry
endfunction

let s:Kind = {
\   'name': 'quickfix',
\   'action_table': {
\     'open': function('s:action_open'),
\     'open!': function('s:action_open_x'),
\   },
\   'key_table': {},
\   'prototype': luis#kind#buffer#import(),
\ }
