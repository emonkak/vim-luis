" ku source: spell
" Module  "{{{1

let s:SOURCE_TEMPLATE = {
\   'name': 'spell',
\   'kind': {
\     'action_table': {
\       'open!': function('ku#source#spell#action_open_x'),
\       'open': function('ku#source#spell#action_open'),
\     },
\     'key_table': {},
\     'prototype': g:ku#kind#common#module,
\   },
\   'matcher': {
\      'match_candidates': function('ku#matcher#raw_match')
\   },
\   'gather_candidates': function('ku#source#spell#gather_candidates'),
\   'on_action': function('ku#source#default#on_action'),
\   'on_source_enter': function('ku#source#default#on_source_enter'),
\   'on_source_leave': function('ku#source#default#on_source_leave'),
\   'special_char_p': function('ku#source#default#special_char_p'),
\   'valid_for_acc_p': function('ku#source#default#valid_for_acc_p'),
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
  put =a:candidate.word
  return 0
endfunction




function! ku#source#spell#action_open_x(candidate) abort  "{{{2
  put! =a:candidate.word
  return 0
endfunction








" __END__  "{{{1
" vim: foldmethod=marker
