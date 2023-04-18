function! ku#source#tagstack#new() abort
  let source = copy(s:Source)
  let source._cached_candidates = []
  return source
endfunction

function! s:action_open(kind, candidate) abort
  let error = ku#kind#do_action(g:ku#kind#buffer#export, 'open', a:candidate)
  if error isnot 0
    return error
  endif
  if has_key(a:candidate.user_data, 'ku_tag_index')
    let index = a:candidate.user_data.ku_tag_index
    call settagstack(winnr(), { 'curidx': index })
  endif
  return 0
endfunction

let s:Source = {
\   'name': 'tagstack',
\   'default_kind': {
\     'action_table': {
\       'open': function('s:action_open'),
\     },
\     'key_table': {},
\     'prototype': g:ku#kind#common#export,
\   },
\   'matcher': g:ku#matcher#default,
\ }

function! s:Source.gather_candidates(pattern) abort dict
  return self._cached_candidates
endfunction

function! s:Source.on_source_enter() abort dict
  let index = 1  " 1-origin
  let candidates = []

  for item in gettagstack(winnr('#')).items
    let bufname = bufname(item.bufnr)
    call add(candidates, {
    \   'word': item.tagname,
    \   'menu': bufname . ':' . item.from[0] . ':' . item.from[1],
    \   'dup': 1,
    \   'ku__sort_priority': index,
    \   'user_data': {
    \     'ku_tag_index': index,
    \     'ku_buffer_bufnr': item.bufnr,
    \     'ku_buffer_cursor': item.from,
    \   },
    \ })
    let index += 1
  endfor

  let self._cached_candidates = candidates
endfunction
