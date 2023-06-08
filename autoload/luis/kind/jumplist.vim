function! luis#kind#jumplist#import() abort
  return s:Kind
endfunction

function! s:action_open(candidate, context) abort
  if !has_key(a:candidate.user_data, 'jumplist_location')
    return 'No location chosen'
  endif
  let location = a:candidate.user_data.jumplist_location
  let current_location = getjumplist()[1]
  let offset = location - current_location
  let v:errmsg = ''
  if offset < 0
    silent! execute 'normal!' (-offset . "\<C-o>")
  elseif offset > 0
    silent! execute 'normal!' (offset . "\<C-i>")
  endif
  if v:errmsg != ''
    return v:errmsg
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
