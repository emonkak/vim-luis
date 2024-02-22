let s:Buffer = luis#kind#buffer#import()

function! luis#kind#tagstack#import() abort
  return s:Kind
endfunction

function! s:action_open(candidate, context) abort
  call s:do_open('open', a:candidate, a:context)
endfunction

function! s:action_open_x(candidate, context) abort
  call s:do_open('open!', a:candidate, a:context)
endfunction

function! s:do_open(action_name, candidate, context) abort
  let Action = s:Buffer.action_table[a:action_name]
  call Action(a:candidate, a:context)
  if has_key(a:candidate.user_data, 'tagstack_index')
    let index = a:candidate.user_data.tagstack_index
    call settagstack(winnr(), { 'curidx': index })
  endif
endfunction

let s:Kind = {
\   'name': 'tagstack',
\   'action_table': {
\     'open': function('s:action_open'),
\     'open!': function('s:action_open_x'),
\   },
\   'key_table': {},
\   'prototype': s:Buffer,
\ }
