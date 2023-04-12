function! ku#source#jumplist#new() abort
  let source = copy(s:Source)
  let source._cached_candidates = []
  return source
endfunction

function! s:action_open(candidate) abort
  let error = ku#kind#buffer#action_open(a:candidate)
  if error isnot 0
    return error
  endif
  if has_key(a:candidate.user_data, 'ku_cursor')
    call cursor(a:candidate.user_data.ku_cursor)
  endif
  return 0
endfunction

function! s:action_open_x(candidate) abort
  let error = ku#kind#buffer#action_open_x(a:candidate)
  if error isnot 0
    return error
  endif
  if has_key(a:candidate.user_data, 'ku_cursor')
    call cursor(a:candidate.user_data.ku_cursor)
  endif
  return 0
endfunction

let s:Source = {
\   'name': 'jumplist',
\   'default_kind': {
\     'action_table': {
\       'open': function('s:action_open'),
\       'open_x': function('s:action_open_x'),
\     },
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
    \     'ku_buffer_nr': location.bufnr,
    \     'ku_cursor': [location.lnum, location.col],
    \   },
    \   'ku__sort_priority': position,
    \ })
    let position -= 1
  endfor
  let self._cached_candidates = candidates
endfunction
