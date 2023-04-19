function! s:action_open(kind, candidate) abort
  let v:errmsg = ''
  execute 'colorscheme' a:candidate.word
  return v:errmsg == '' ? 0 : v:errmsg
endfunction

let g:luis#kind#colorscheme#export = {
\   'name': 'colorscheme',
\   'action_table': {
\     'open': function('s:action_open'),
\   },
\   'key_table': {},
\   'prototype': luis#kind#common#export,
\ }
