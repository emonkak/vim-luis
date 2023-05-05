function! s:action_cd(kind, candidate) abort
  let path = s:path_from_candidate(a:candidate)
  try
    cd `=fnamemodify(path, ':p:h')`
  catch
    return v:exception
  endtry
  return 0
endfunction

function! s:action_lcd(kind, candidate) abort
  let path = s:path_from_candidate(a:candidate)
  try
    lcd `=fnamemodify(path, ':p:h')`
  catch
    return v:exception
  endtry
  return 0
endfunction

function! s:action_tcd(kind, candidate) abort
  let path = s:path_from_candidate(a:candidate)
  try
    tcd `=fnamemodify(path, ':p:h')`
  catch
    return v:exception
  endtry
  return 0
endfunction

function! s:action_open(kind, candidate) abort
  return s:open('edit', a:candidate)
endfunction

function! s:action_open_x(kind, candidate) abort
  return s:open('edit!', a:candidate)
endfunction

function! s:open(command, candidate) abort
  let path = s:path_from_candidate(a:candidate)
  if path == ''
    return 'No file chosen'
  endif
  try
    execute a:command '`=fnamemodify(path, ":.")`'
    if has_key(a:candidate.user_data, 'file_pos')
      call cursor(a:candidate.user_data.file_pos)
      normal! zvzt
    endif
  catch
    return v:exception
  endtry
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

if exists(':tcd')
  let g:luis#kind#file#export.action_table.tcd = function('s:action_tcd')
  let g:luis#kind#file#export.key_table["\<C-_>"] = 'tcd'
endif
