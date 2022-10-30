" ku source: args
" Module  "{{{1

let s:SOURCE_TEMPLATE = {
\   'name': 'args',
\   'kind': {
\     'action_table': {
\       'argdelete': function('ku#source#args#action_argdelete'),
\     },
\     'key_table': {
\       'D': 'argdelete',
\     },
\     'prototype': g:ku#kind#buffer#module,
\   },
\   'matcher': g:ku#matcher#default,
\   'gather_candidates': function('ku#source#args#gather_candidates'),
\   'on_action': function('ku#source#default#on_action'),
\   'on_source_enter': function('ku#source#args#on_source_enter'),
\   'on_source_leave': function('ku#source#default#on_source_leave'),
\   'special_char_p': function('ku#source#default#special_char_p'),
\   'valid_for_acc_p': function('ku#source#default#valid_for_acc_p'),
\ }

function! ku#source#args#new() abort
  return extend({'_cached_candidates': []}, s:SOURCE_TEMPLATE, 'keep')
endfunction








" Interface  "{{{1
function! ku#source#args#gather_candidates(pattern) abort dict  "{{{2
  return self._cached_candidates
endfunction




function! ku#source#args#on_source_enter() abort dict  "{{{2
  let self._cached_candidates = map(argv(), '{"word": v:val}')
endfunction








" Actions  "{{{1
function! ku#source#args#action_argdelete(candidate) abort  "{{{2
  let v:errmsg = ''
  silent! execute 'argdelete' fnameescape(a:candidate.word)
  return v:errmsg == '' ? 0 : v:errmsg
endfunction








" __END__  "{{{1
" vim: foldmethod=marker
