function! luis#kind#changelist#import() abort
  return s:Kind
endfunction

function! s:action_open(candidate, context) abort
  if !has_key(a:candidate.user_data, 'changelist_index')
  \  || !has_key(a:candidate.user_data, 'changelist_bufnr')
    throw 'luis(kind.changelist): No change chosen'
  endif
  let index = a:candidate.user_data.changelist_index
  let changelist = getchangelist(a:candidate.user_data.changelist_bufnr)
  if !empty(changelist)
  let current_index = changelist[1]
  let offset = index - current_index
    if offset < 0
      execute 'normal!' (-offset . 'g;')
    elseif offset > 0
      execute 'normal!' (offset . 'g,')
    endif
  endif
endfunction

let s:Kind = {
\   'name': 'changelist',
\   'action_table': {
\     'open': function('s:action_open'),
\   },
\   'key_table': {},
\   'prototype': luis#kind#buffer#import(),
\ }
