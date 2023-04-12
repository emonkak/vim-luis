function! ku#source#project#new(directory, source_func, options = {}) abort
  let source = copy(s:Source)
  let source._directory = a:directory
  let source._source_func = a:source_func
  let source._options = a:options
  let source._cached_candidates = []
  return source
endfunction

function! s:action_open(candidate) abort
  if has_key(a:candidate.user_data, 'ku_file_path')
    let source = a:candidate.user_data.ku__source._source_func()
    let options = a:candidate.user_data.ku__source._options
    cd `=a:candidate.user_data.ku_file_path`
    call ku#start(source, options)
    return 0
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
    \     'ku_file_path': path,
    \   },
    \ })
  endfor
  let self._cached_candidates = candidates
endfunction
