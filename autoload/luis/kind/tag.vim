function! s:action_open(kind, candidate) abort
  try
    execute 'tag' a:candidate.word
  catch
    return v:exception
  endtry
  return 0
endfunction

function! s:action_open_x(kind, candidate) abort
  try
    execute 'tag!' a:candidate.word
  catch
    return v:exception
  endtry
  return 0
endfunction

let g:luis#kind#tag#export = {
\   'name': 'tag',
\   'action_table': {
\     'open': function('s:action_open'),
\     'open!': function('s:action_open_x'),
\   },
\   'key_table': {},
\   'prototype': g:luis#kind#common#export,
\ }
