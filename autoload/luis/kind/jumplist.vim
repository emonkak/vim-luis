function! luis#kind#jumplist#import() abort
  return s:Kind
endfunction

function! s:action_open(candidate, context) abort
  if !has_key(a:candidate.user_data, 'jumplist_index')
    throw 'luis(kind.jumplist): No jumplist chosen'
  endif
  let index = a:candidate.user_data.jumplist_index
  let current_index = getjumplist()[1]
  let offset = index - current_index
  if offset < 0
    execute 'normal!' (-offset . "\<C-o>")
  elseif offset > 0
    execute 'normal!' (offset . "\<C-i>")
  endif
endfunction

let s:Kind = {
\   'name': 'jumplist',
\   'action_table': {
\     'open': function('s:action_open'),
\   },
\   'key_table': {},
\   'prototype': luis#kind#buffer#import(),
\ }
