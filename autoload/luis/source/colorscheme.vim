function! luis#source#colorscheme#new() abort
  let source = copy(s:Source)
  let source._cached_candidates = []
  return source
endfunction

function! s:action_open(kind, candidate) abort
  let v:errmsg = ''
  execute 'colorscheme' a:candidate.word
  return v:errmsg == '' ? 0 : v:errmsg
endfunction

let s:Source = {
\   'name': 'colorscheme',
\   'default_kind': {
\     'name': 'colorscheme',
\     'action_table': {
\       'open': function('s:action_open'),
\     },
\     'key_table': {},
\     'prototype': luis#kind#common#export,
\   },
\   'matcher': g:luis#matcher#default,
\ }

function! s:Source.gather_candidates(pattern) abort dict
  return self._cached_candidates
endfunction

function! s:Source.on_source_enter() abort dict
  let colorschemes = globpath(&runtimepath, 'colors/*.vim', 0, 1)
  let self._cached_candidates = map(colorschemes, '{
  \   "word": fnamemodify(v:val, ":t:r"),
  \   "menu": fnamemodify(v:val, ":p:h:h"),
  \ }')
endfunction
