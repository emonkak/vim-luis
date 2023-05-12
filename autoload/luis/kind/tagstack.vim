function! luis#kind#tagstack#import() abort
  return s:Kind
endfunction

function! s:action_open(candidate, context) abort
  return s:do_open('open', a:candidate, a:context)
endfunction

function! s:action_open_x(candidate, context) abort
  return s:do_open('open!', a:candidate, a:context)
endfunction

function! s:do_open(action_name, candidate, context) abort
  let error = luis#do_action(
  \   a:context.kind.prototype,
  \   a:action_name,
  \   a:candidate
  \ )
  if error isnot 0
    return error
  endif
  if has_key(a:candidate.user_data, 'tagstack_index')
    let index = a:candidate.user_data.tagstack_index
    call settagstack(winnr(), { 'curidx': index })
  endif
  return 0
endfunction

let s:Kind = {
\   'name': 'tagstack',
\   'action_table': {
\     'open': function('s:action_open'),
\     'open!': function('s:action_open_x'),
\   },
\   'key_table': {},
\   'prototype': luis#kind#buffer#import(),
\ }
