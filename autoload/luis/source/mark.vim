function! luis#source#mark#new() abort
  let source = copy(s:Source)
  let source._cached_candidates = []
  return source
endfunction

function! s:action_delete(kind, candidate) abort
  if !has_key(a:candidate.user_data, 'mark_name')
    return 'No mark found'
  endif
  execute 'delmarks' a:candidate.user_data.mark_name
  return 0
endfunction

function! s:action_open(kind, candidate) abort
  if !has_key(a:candidate.user_data, 'mark_name')
    return 'No mark found'
  endif
  execute 'normal!' '`' . a:candidate.mark_name
  return 0
endfunction

let s:Source = {
\   'name': 'mark',
\   'default_kind': {
\     'name': 'mark',
\     'action_table': {
\       'open': function('s:action_open'),
\       'delete': function('s:action_delete'),
\     },
\     'key_table': {
\       "\<C-d>": 'delete',
\       'd': 'delete',
\     },
\     'prototype': g:luis#kind#common#export,
\   },
\   'matcher': g:luis#matcher#default,
\ }

function! s:Source.gather_candidates(pattern) abort dict
  return self._cached_candidates
endfunction

function! s:Source.on_source_enter() abort dict
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
    \     'mark_name': mark_name,
    \   },
    \   'luis_sort_priority': char2nr(mark_name),
    \ })
  endfor
  for mark in getmarklist()  " global marks
    let mark_name = mark.mark[1:]
    call add(candidates, {
    \   'word': mark.file . ':' . mark.pos[1] . ':' . mark.pos[2],
    \   'menu': 'mark ' . mark_name,
    \   'dup': 1,
    \   'user_data': {
    \     'mark_name': mark_name,
    \   },
    \   'luis_sort_priority': char2nr(mark_name),
    \ })
  endfor
  let self._cached_candidates = candidates
endfunction
