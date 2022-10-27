" ku kind: buffer
" Module  "{{{1

let g:ku#kind#buffer#module = {
\   'action_table': {
\     'delete': function('ku#kind#buffer#action_delete'),
\     'open!': function('ku#kind#buffer#action_open_x'),
\     'open': function('ku#kind#buffer#action_open'),
\     'unload': function('ku#kind#buffer#action_unload'),
\     'wipeout': function('ku#kind#buffer#action_wipeout'),
\   },
\   'key_table': {
\     'D': 'delete',
\     'U': 'unload',
\     'W': 'wipeout',
\   },
\   'prototype': g:ku#kind#common#module,
\ }








" Actions  "{{{1
function! ku#kind#buffer#action_delete(candidate) abort  "{{{2
  return s:delete('bdelete', a:candidate)
endfunction




function! ku#kind#buffer#action_open(candidate) abort  "{{{2
  return s:open('', a:candidate)
endfunction




function! ku#kind#buffer#action_open_x(candidate) abort  "{{{2
  return s:open('!', a:candidate)
endfunction




function! ku#kind#buffer#action_unload(candidate) abort  "{{{2
  return s:delete('bunload', a:candidate)
endfunction




function! ku#kind#buffer#action_wipeout(candidate) abort  "{{{2
  return s:delete('bwipeout', a:candidate)
endfunction








" Misc.  "{{{1
function! s:bufnr_from_candidate(candidate) abort  "{{{2
  if has_key(a:candidate.user_data, 'ku_buffer_nr')
    return a:candidate.user_data.ku_buffer_nr
  else
    let bufnr = bufnr(fnameescape(a:candidate.word))
    if 1 <= bufnr
      return bufnr
    else
      return ('There is no corresponding buffer to candidate: '
      \       . string(a:candidate.word))
    endif
  endif
endfunction




function! s:delete(delete_command, candidate) abort  "{{{2
  let bufnr = s:bufnr_from_candidate(a:candidate)
  if type(bufnr) != v:t_number
    return bufnr
  endif
  let v:errmsg = ''
  execute bufnr a:delete_command
  return v:errmsg == '' ? 0 : v:errmsg
endfunction




function! s:open(bang, candidate) abort  "{{{2
  let bufnr = s:bufnr_from_candidate(a:candidate)
  if type(bufnr) != v:t_number
    return bufnr
  endif
  let v:errmsg = ''
  execute bufnr 'buffer'.a:bang
  return v:errmsg == '' ? 0 : v:errmsg
endfunction








" __END__  "{{{1
" vim: foldmethod=marker
