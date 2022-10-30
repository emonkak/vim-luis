" ku source: jumplist
" Module  "{{{1

let s:SOURCE_TEMPLATE = {
\   'name': 'jumplist',
\   'kind': {
\     'action_table': {
\       'open': function('ku#source#jumplist#action_open'),
\       'open_x': function('ku#source#jumplist#action_open_x'),
\     },
\     'key_table': {},
\     'prototype': g:ku#kind#buffer#module,
\   },
\   'matcher': g:ku#matcher#default,
\   'gather_candidates': function('ku#source#jumplist#gather_candidates'),
\   'on_action': function('ku#source#default#on_action'),
\   'on_source_enter': function('ku#source#jumplist#on_source_enter'),
\   'on_source_leave': function('ku#source#default#on_source_leave'),
\   'special_char_p': function('ku#source#default#special_char_p'),
\   'valid_for_acc_p': function('ku#source#default#valid_for_acc_p'),
\ }

function! ku#source#jumplist#new() abort
  return extend({'_cached_candidates': []}, s:SOURCE_TEMPLATE, 'keep')
endfunction








" Interface  "{{{1
function! ku#source#jumplist#gather_candidates(pattern) abort dict  "{{{2
  return self._cached_candidates
endfunction




function! ku#source#jumplist#on_source_enter() abort dict  "{{{2
  let candidates = []
  let last_winnr = winnr('#')
  if last_winnr == 0
    return candidates
  endif
  let [locations, last_position] = getjumplist(last_winnr)
  let position = last_position
  for location in locations
    if !bufexists(location.bufnr) || getbufvar(location.bufnr, '&buftype') != ''
      continue
    endif
    let bufname = bufname(location.bufnr)
    call add(candidates, {
    \   'word': bufname,
    \   'abbr': bufname . ':' . location.lnum . ':' . location.col,
    \   'menu': 'jump ' . position,
    \   'dup': 1,
    \   'user_data': {
    \     'ku_buffer_nr': location.bufnr,
    \     'ku_cursor': [location.lnum, location.col],
    \   },
    \   'ku__sort_priority': last_position - position,
    \ })
    let position -= 1
  endfor
  let self._cached_candidates = candidates
endfunction








" Actions  "{{{1
function! ku#source#jumplist#action_open(candidate) abort  "{{{2
  let error = ku#kind#buffer#action_open(a:candidate)
  if error isnot 0
    return error
  endif
  if has_key(a:candidate.user_data, 'ku_cursor')
    call cursor(a:candidate.user_data.ku_cursor)
  endif
  return 0
endfunction





function! ku#source#jumplist#action_open_x(candidate) abort  "{{{2
  let error = ku#kind#buffer#action_open_x(a:candidate)
  if error isnot 0
    return error
  endif
  if has_key(a:candidate.user_data, 'ku_cursor')
    call cursor(a:candidate.user_data.ku_cursor)
  endif
  return 0
endfunction









" __END__  "{{{1
" vim: foldmethod=marker

