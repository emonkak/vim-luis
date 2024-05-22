function! luis#kind#jumplist#import() abort
  return s:Kind
endfunction

function! s:action_open(candidate, context) abort
  if !has_key(a:candidate.user_data, 'jumplist_index')
  \  || !has_key(a:candidate.user_data, 'jumplist_window')
    throw 'luis(kind.jumplist): No jump chosen'
  endif
  let index = a:candidate.user_data.jumplist_index
  let jumplist = getjumplist(a:candidate.user_data.jumplist_window)
  if !empty(jumplist)
    let offset = index - jumplist[1]
    if offset < 0
      execute 'normal!' (-offset . "\<C-o>")
    elseif offset > 0
      execute 'normal!' (offset . "\<C-i>")
    endif
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
