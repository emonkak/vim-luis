" ku source: mark
" Module  "{{{1

let s:SOURCE_TEMPLATE = {
\   'name': 'mark',
\   'kind': {
\     'action_table': {
\       'open': function('ku#source#mark#action_open'),
\       'delete': function('ku#source#mark#action_delete'),
\     },
\     'key_table': {
\       "\<C-d>": 'delete',
\       'd': 'delete',
\     },
\     'prototype': g:ku#kind#common#module,
\   },
\   'matcher': g:ku#matcher#default,
\   'gather_candidates': function('ku#source#mark#gather_candidates'),
\   'on_action': function('ku#source#default#on_action'),
\   'on_source_enter': function('ku#source#mark#on_source_enter'),
\   'on_source_leave': function('ku#source#default#on_source_leave'),
\   'special_char_p': function('ku#source#default#special_char_p'),
\   'valid_for_acc_p': function('ku#source#default#valid_for_acc_p'),
\ }

function! ku#source#mark#new() abort
  return extend({'_cached_candidates': []}, s:SOURCE_TEMPLATE, 'keep')
endfunction








" Interface  "{{{1
function! ku#source#mark#gather_candidates(pattern) abort dict  "{{{2
  return self._cached_candidates
endfunction




function! ku#source#mark#on_source_enter() abort dict  "{{{2
  let candidates = []
  let bufnr = bufnr('#')
  let bufname = bufname(bufnr)
  for mark in getmarklist(bufnr)  " buffer local marks
    let mark_name = mark.mark[1:]
    call add(candidates, {
    \   'word': bufname . ':' . mark.pos[1] . ':' . mark.pos[2],
    \   'menu': 'mark ' . mark_name,
    \   'dup': 1,
    \   'user_data': {
    \     'ku_mark': mark_name,
    \   },
    \   'ku__sort_priority': char2nr(mark_name),
    \ })
  endfor
  for mark in getmarklist()  " global maarks
    let mark_name = mark.mark[1:]
    call add(candidates, {
    \   'word': mark.file . ':' . mark.pos[1] . ':' . mark.pos[2],
    \   'menu': 'mark ' . mark_name,
    \   'dup': 1,
    \   'user_data': {
    \     'ku_mark': mark_name,
    \   },
    \   'ku__sort_priority': char2nr(mark_name),
    \ })
  endfor
  let self._cached_candidates = candidates
endfunction








" Actions  "{{{1
function! ku#source#mark#action_delete(candidate) abort  "{{{2
  if !has_key(a:candidate.user_data, 'ku_mark')
    return 'No mark found'
  endif
  execute 'delmarks' a:candidate.user_data.ku_mark
  return 0
endfunction





function! ku#source#mark#action_open(candidate) abort  "{{{2
  if !has_key(a:candidate.user_data, 'ku_mark')
    return 'No mark found'
  endif
  execute 'normal!' '`' . a:candidate.user_data.ku_mark
  return 0
endfunction









" __END__  "{{{1
" vim: foldmethod=marker
