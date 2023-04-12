function! ku#source#spell#new() abort
  return s:Source
endfunction

function! s:action_open(candidate) abort
  execute 'normal!' "i\<C-r>" . '=a:candidate.word' . "\<CR>\<Esc>"
  return 0
endfunction

function! s:action_put(candidate) abort
  put =a:candidate.word
  return 0
endfunction

function! s:action_put_x(candidate) abort
  put! =a:candidate.word
  return 0
endfunction

let s:Source = {
\   'name': 'spell',
\   'default_kind': {
\     'action_table': {
\       'open': function('s:action_open'),
\       'put!': function('s:action_put_x'),
\       'put': function('s:action_put'),
\     },
\     'key_table': {
\       'P': 'put!',
\       'p': 'put',
\     },
\     'prototype': g:ku#kind#common#export,
\   },
\   'matcher': g:ku#matcher#raw,
\   'gather_candidates': function('ku#source#spell#gather_candidates'),
\ }

function! s:Source.gather_candidates(pattern) abort dict
  return map(spellsuggest(a:pattern), '{ "word": v:val }')
endfunction
