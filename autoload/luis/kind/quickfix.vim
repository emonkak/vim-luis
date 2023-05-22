function! luis#kind#quickfix#import() abort
  return s:Kind
endfunction

function! s:action_open(candidate, context) abort
  return s:do_open('cc', a:candidate)
endfunction

function! s:action_open_x(candidate, context) abort
  return s:do_open('cc!', a:candidate)
endfunction

function! s:do_open(command, candidate) abort
  if !has_key(a:candidate.user_data, 'quickfix_nr')
    return 'No error chosen'
  endif

  let original_switchbuf = &switchbuf
  let &switchbuf = ''
  try
    execute a:command a:candidate.user_data.quickfix_nr
  catch
    return v:exception
  finally
    let &switchbuf = original_switchbuf
  endtry

  return 0
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
