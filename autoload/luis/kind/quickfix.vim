function! s:action_open(kind, candidate) abort
  return s:open('', a:candidate)
endfunction

function! s:action_open_x(kind, candidate) abort
  return s:open('!', a:candidate)
endfunction

function! s:open(bang, candidate) abort
  if !has_key(a:candidate.user_data, 'quickfix_nr')
    return 'No error found'
  endif

  let v:errmsg = ''

  let original_switchbuf = &switchbuf
  let &switchbuf = ''
  try
    execute ('cc' . a:bang) a:candidate.user_data.quickfix_nr
  finally
    let &switchbuf = original_switchbuf
  endtry

  return v:errmsg == '' ? 0 : v:errmsg
endfunction

let g:luis#kind#quickfix#export = {
\   'name': 'quickfix',
\   'action_table': {
\     'open': function('s:action_open'),
\     'open!': function('s:action_open_x'),
\   },
\   'key_table': {},
\   'prototype': g:luis#kind#buffer#export,
\ }
