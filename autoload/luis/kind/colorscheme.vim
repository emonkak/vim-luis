function! s:action_open(kind, candidate) abort
  try
    execute 'colorscheme' a:candidate.word
  catch
    return v:exception
  endtry
  return 0
endfunction

let g:luis#kind#colorscheme#export = {
\   'name': 'colorscheme',
\   'action_table': {
\     'open': function('s:action_open'),
\   },
\   'key_table': {},
\   'prototype': luis#kind#common#export,
\ }
