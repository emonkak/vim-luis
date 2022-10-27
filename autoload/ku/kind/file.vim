" ku kind: file
" Module  "{{{1

let g:ku#kind#file#module = {
\   'action_table': {
\     'open!': function('ku#kind#file#action_open_x'),
\     'open': function('ku#kind#file#action_open'),
\   },
\   'key_table': {},
\   'prototype': g:ku#kind#common#module,
\ }








" Actions  "{{{1
function! ku#kind#file#action_open(candidate) abort  "{{{2
  return s:open('', a:candidate)
endfunction




function! ku#kind#file#action_open_x(candidate) abort  "{{{2
  return s:open('!', a:candidate)
endfunction




" Misc.  "{{{1
function! s:open(bang, candidate) abort  "{{{2
  let path = s:path_from_candidate(a:candidate)
  execute 'edit'.a:bang '`=path`'
  return 0
endfunction




function! s:path_from_candidate(candidate) abort  "{{{2
  return has_key(a:candidate, 'user_data')
  \      && has_key(a:candidate.user_data, 'ku_file_path')
  \       ? a:candidate.user_data.ku_file_path
  \       : a:candidate.word
endfunction








" __END__  "{{{1
" vim: foldmethod=marker
