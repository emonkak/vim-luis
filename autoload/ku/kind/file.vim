function! s:action_cd(candidate) abort
  let path = s:path_from_candidate(a:candidate)
  let v:errmsg = ''
  silent! cd `=fnamemodify(path, ':p:h')`
  return v:errmsg == '' ? 0 : v:errmsg
endfunction

function! s:action_lcd(candidate) abort
  let path = s:path_from_candidate(a:candidate)
  let v:errmsg = ''
  silent! lcd `=fnamemodify(patht, ':p:h')`
  return v:errmsg == '' ? 0 : v:errmsg
endfunction

function! s:action_open(candidate) abort
  return s:open('', a:candidate)
endfunction

function! s:action_open_x(candidate) abort
  return s:open('!', a:candidate)
endfunction

function! s:open(bang, candidate) abort
  let path = s:path_from_candidate(a:candidate)
  if path == ''
    return 'No file chosen'
  endif
  execute 'edit'.a:bang '`=path`'
  if has_key(a:candidate.user_data, 'ku_file_cursor')
    call cursor(a:candidate.user_data.ku_file_cursor)
  endif
  return 0
endfunction

function! s:path_from_candidate(candidate) abort
  return has_key(a:candidate.user_data, 'ku_file_path')
  \      ? a:candidate.user_data.ku_file_path
  \      : a:candidate.word
endfunction

let g:ku#kind#file#export = {
\   'action_table': {
\     'cd': function('s:action_cd'),
\     'lcd': function('s:action_lcd'),
\     'open!': function('s:action_open_x'),
\     'open': function('s:action_open'),
\   },
\   'key_table': {
\     '/': 'cd',
\     '?': 'lcd',
\   },
\   'prototype': g:ku#kind#common#export,
\ }
