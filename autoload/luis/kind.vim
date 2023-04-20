function! luis#kind#call_action(kind, action_name, candidate) abort
  let Action = s:find_action(a:kind, a:action_name)
  if Action is 0
    return 'Action' string(a:action_name) 'is not defined'
  endif
  return Action(a:kind, a:candidate)
endfunction

function! luis#kind#composite_key_table(kind) abort
  let key_table = {}
  let kind = a:kind

  while v:true
    call extend(key_table, kind.key_table)
    if !has_key(kind, 'prototype')
      break
    endif
    let kind = kind.prototype
  endwhile

  return key_table
endfunction

function! s:find_action(kind, action_name) abort
  let kind = a:kind

  while v:true
    if has_key(kind.action_table, a:action_name)
      return kind.action_table[a:action_name]
    endif
    if !has_key(kind, 'prototype')
      break
    endif
    let kind = kind.prototype
  endwhile

  return 0
endfunction
