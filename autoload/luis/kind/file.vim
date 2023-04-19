function! s:action_cd(kind, candidate) abort
  let path = s:path_from_candidate(a:candidate)
  let v:errmsg = ''
  silent! cd `=fnamemodify(path, ':p:h')`
  return v:errmsg == '' ? 0 : v:errmsg
endfunction

function! s:action_lcd(kind, candidate) abort
  let path = s:path_from_candidate(a:candidate)
  let v:errmsg = ''
  silent! lcd `=fnamemodify(patht, ':p:h')`
  return v:errmsg == '' ? 0 : v:errmsg
endfunction

function! s:action_open(kind, candidate) abort
  return s:open('', a:candidate)
endfunction

function! s:action_open_x(kind, candidate) abort
  return s:open('!', a:candidate)
endfunction

function! s:open(bang, candidate) abort
  let path = s:path_from_candidate(a:candidate)
  if path == ''
    return 'No file chosen'
  endif
  execute ('edit' . a:bang) '`=fnamemodify(path, ":.")`'
  if has_key(a:candidate.user_data, 'file_pos')
    call cursor(a:candidate.user_data.file_pos)
  endif
  return 0
endfunction

function! s:path_from_candidate(candidate) abort
  return has_key(a:candidate.user_data, 'file_path')
  \      ? a:candidate.user_data.file_path
  \      : a:candidate.word
endfunction

let g:luis#kind#file#export = {
\   'name': 'file',
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
\   'prototype': g:luis#kind#common#export,
\ }