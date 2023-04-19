function! s:action_open(kind, candidate) abort
  let error = luis#kind#call_action(kind.prototype, 'open', a:candidate)
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
\   },
\   'key_table': {},
\   'prototype': g:luis#kind#buffer#export,
\ }
