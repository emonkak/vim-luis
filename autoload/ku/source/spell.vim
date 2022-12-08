" ku source: spell
" Module  "{{{1

let s:SOURCE_TEMPLATE = {
\   'name': 'spell',
\   'default_kind': {
\     'action_table': {
\       'open': function('ku#source#spell#action_open'),
\       'put!': function('ku#source#spell#action_put_x'),
\       'put': function('ku#source#spell#action_put'),
\     },
\     'key_table': {
\       'P': 'put!',
\       'p': 'put',
\     },
\     'prototype': g:ku#kind#common#export,
\   },
\   'matcher': {
\      'match_candidates': function('ku#matcher#raw_match')
\   },
\   'gather_candidates': function('ku#source#spell#gather_candidates'),
\ }

function! ku#source#spell#new() abort
  return copy(s:SOURCE_TEMPLATE)
endfunction








" Interface  "{{{1
function! ku#source#spell#gather_candidates(pattern) abort dict  "{{{2
  return map(spellsuggest(a:pattern), '{ "word": v:val }')
endfunction




" Actions  "{{{1
function! ku#source#spell#action_open(candidate) abort  "{{{2
  execute 'normal!' "i\<C-r>" . '=a:candidate.word' . "\<CR>\<Esc>"
  return 0
endfunction




function! ku#source#spell#action_put(candidate) abort  "{{{2
  put =a:candidate.word
  return 0
endfunction




function! ku#source#spell#action_put_x(candidate) abort  "{{{2
  put! =a:candidate.word
  return 0
endfunction








" __END__  "{{{1
" vim: foldmethod=marker
