function! s:action_open(kind, candidate) abort
  return s:do_open(a:kind, 'open', a:candidate)
endfunction

function! s:action_open_x(kind, candidate) abort
  return s:do_open(a:kind, 'open!', a:candidate)
endfunction

function! s:do_open(kind, action_name, candidate) abort
  let error = luis#internal#do_action(a:kind.prototype, a:action_name, a:candidate)
  if error isnot 0
    return error
  endif
  if has_key(a:candidate.user_data, 'tagstack_index')
    let index = a:candidate.user_data.tagstack_index
    call settagstack(winnr(), { 'curidx': index })
  endif
  return 0
endfunction

let g:luis#kind#tagstack#export = {
\   'name': 'tagstack',
\   'action_table': {
\     'open': function('s:action_open'),
\     'open!': function('s:action_open_x'),
\   },
\   'key_table': {},
\   'prototype': g:luis#kind#buffer#export,
\ }
