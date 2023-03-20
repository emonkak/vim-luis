" ku source: colorscheme
" Module  "{{{1

let s:SOURCE_TEMPLATE = {
\   'name': 'colorscheme',
\   'default_kind': {
\     'action_table': {
\       'open': function('ku#source#colorscheme#action_open'),
\     },
\     'key_table': {},
\     'prototype': ku#kind#common#export,
\   },
\   'matcher': g:ku#matcher#default,
\   'gather_candidates': function('ku#source#colorscheme#gather_candidates'),
\   'on_source_enter': function('ku#source#colorscheme#on_source_enter'),
\ }

function! ku#source#colorscheme#new() abort
  return extend({'_cached_candidates': []}, s:SOURCE_TEMPLATE, 'keep')
endfunction








" Interface  "{{{1
function! ku#source#colorscheme#gather_candidates(pattern) abort dict  "{{{2
  return self._cached_candidates
endfunction




function! ku#source#colorscheme#on_source_enter() abort dict  "{{{2
  let colorschemes = globpath(&runtimepath, 'colors/*.vim', 0, 1)
  let self._cached_candidates = map(colorschemes, '{
  \   "word": fnamemodify(v:val, ":t:r"),
  \   "menu": fnamemodify(v:val, ":p:h:h"),
  \ }')
endfunction








" Actions  "{{{1
function! ku#source#colorscheme#action_open(candidate) abort  "{{{2
  let v:errmsg = ''
  execute 'colorscheme' a:candidate.word
  return v:errmsg == '' ? 0 : v:errmsg
endfunction








" __END__  "{{{1
" vim: foldmethod=marker
