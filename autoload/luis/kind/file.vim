function! luis#kind#file#import() abort
  return s:Kind
endfunction

function! s:action_cd(candidate, context) abort
  let path = s:path_from_candidate(a:candidate)
  cd `=fnamemodify(path, ':p:h')`
endfunction

function! s:action_lcd(candidate, context) abort
  let path = s:path_from_candidate(a:candidate)
  lcd `=fnamemodify(path, ':p:h')`
endfunction

function! s:action_tcd(candidate, context) abort
  let path = s:path_from_candidate(a:candidate)
  tcd `=fnamemodify(path, ':p:h')`
endfunction

function! s:action_open(candidate, context) abort
  call s:do_open('edit', a:candidate)
endfunction

function! s:action_open_x(candidate, context) abort
  call s:do_open('edit!', a:candidate)
endfunction

function! s:do_open(command, candidate) abort
  let path = s:path_from_candidate(a:candidate)
  if path == ''
    throw 'luis(kind.file): No file chosen'
  endif
  try
    execute a:command fnamemodify(path, ':.')
  catch /:E325:/
    " Ignore ATTENTION errors.
  endtry
  if has_key(a:candidate.user_data, 'file_cursor')
    call cursor(a:candidate.user_data.file_cursor)
    normal! zvzt
  endif
endfunction

function! s:path_from_candidate(candidate) abort
  return has_key(a:candidate.user_data, 'file_path')
  \      ? a:candidate.user_data.file_path
  \      : a:candidate.word
endfunction

let s:Kind = {
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
\   'prototype': luis#kind#common#import(),
\ }

if exists(':tcd')
  let s:Kind.action_table.tcd = function('s:action_tcd')
  let s:Kind.key_table["\<C-_>"] = 'tcd'
endif
