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
  try
    if offset < 0
      execute 'normal!' (-offset . "\<C-o>")
    elseif offset > 0
      execute 'normal!' (offset . "\<C-i>")
    endif
  catch
    return v:exception
  endtry
endfunction

let s:Kind = {
\   'name': 'jumplist',
\   'action_table': {
\     'open': function('s:action_open'),
\   },
\   'key_table': {},
\   'prototype': luis#kind#buffer#import(),
\ }
