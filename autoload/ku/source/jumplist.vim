function! ku#source#jumplist#new() abort
  let source = copy(s:Source)
  let source._cached_candidates = []
  return source
endfunction

let s:Source = {
\   'name': 'jumplist',
\   'default_kind': {
\     'action_table': {},
\     'key_table': {},
\     'prototype': g:ku#kind#buffer#export,
\   },
\   'matcher': g:ku#matcher#default,
\ }

function! s:Source.gather_candidates(pattern) abort dict
  return self._cached_candidates
endfunction

function! s:Source.on_source_enter() abort dict
  let candidates = []
  let last_winnr = winnr('#')
  if last_winnr == 0
    return
  endif
  let [locations, position] = getjumplist(last_winnr)
  for location in locations
    let bufname = bufname(location.bufnr)
    call add(candidates, {
    \   'word': bufname . ':' . location.lnum . ':' . location.col,
    \   'menu': 'jump ' . position,
    \   'dup': 1,
    \   'user_data': {
    \     'ku_buffer_bufnr': location.bufnr,
    \     'ku_buffer_cursor': [location.lnum, location.col],
    \   },
    \   'ku__sort_priority': position,
    \ })
    let position -= 1
  endfor
  let self._cached_candidates = candidates
endfunction
