function! ku#source#project#new(directory, callback) abort
  let source = copy(s:Source)
  let source._directory = a:directory
  let source._callback = a:callback
  let source._cached_candidates = []
  return source
endfunction

function! s:action_open(candidate) abort
  if has_key(a:candidate.user_data, 'ku_project_path')
    let path = a:candidate.user_data.ku_project_path
    let Callback = a:candidate.user_data.ku_project_callback
    let v:errmsg = ''
    call Callback(path)
    return v:errmsg != '' ? v:errmsg : 0
  else
    return 'No such directory: ' . string(a:candidate.word)
  endif
endfunction

let s:Source = {
\   'name': 'project',
\   'default_kind': {
\     'action_table': {
\       'open': function('s:action_open'),
\     },
\     'key_table': {},
\     'prototype': g:ku#kind#common#export,
\   },
\   'matcher': g:ku#matcher#default,
\ }

function! s:Source.gather_candidates(pattern) abort dict
  return self._cached_candidates
endfunction

function! s:Source.on_source_enter() abort dict
  let candidates = []
  for path in globpath(self._directory, '*/', 0, 1)
    let path = trim(path, '/', 2)
    call add(candidates, {
    \   'word': fnamemodify(path, ':t'),
    \   'user_data': {
    \     'ku_project_path': path,
    \     'ku_project_callback': self._callback,
    \   },
    \ })
  endfor
  let self._cached_candidates = candidates
endfunction
