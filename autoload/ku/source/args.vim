function! ku#source#args#new() abort
  let source = copy(s:Source)
  let source._cached_candidates = []
  return source
endfunction

function! s:action_argdelete(kind, candidate) abort
  let v:errmsg = ''
  silent! execute 'argdelete' fnameescape(a:candidate.word)
  return v:errmsg == '' ? 0 : v:errmsg
endfunction

let s:Source = {
\   'name': 'args',
\   'default_kind': {
\     'action_table': {
\       'argdelete': function('s:action_argdelete'),
\     },
\     'key_table': {
\       'D': 'argdelete',
\     },
\     'prototype': g:ku#kind#buffer#export,
\   },
\   'matcher': g:ku#matcher#default,
\ }

function! s:Source.gather_candidates(pattern) abort dict
  return self._cached_candidates
endfunction

function! s:Source.on_source_enter() abort dict
  let self._cached_candidates = map(argv(), '{ "word": v:val }')
endfunction
