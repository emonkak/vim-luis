" ku source: project
" Module  "{{{1

let s:SOURCE_TEMPLATE = {
\   'name': 'project',
\   'default_kind': {
\     'action_table': {
\       'open': function('ku#source#project#action_open'),
\     },
\     'key_table': {},
\     'prototype': g:ku#kind#common#export,
\   },
\   'matcher': g:ku#matcher#default,
\   'gather_candidates': function('ku#source#project#gather_candidates'),
\   'on_source_enter': function('ku#source#project#on_source_enter'),
\ }

function! ku#source#project#new(directory, source) abort
  return extend({
  \   '_source': a:source,
  \   '_directory': a:directory,
  \   '_cached_candidates': [],
  \ }, s:SOURCE_TEMPLATE, 'keep')
endfunction








" Interface  "{{{1
function! ku#source#project#gather_candidates(pattern) abort dict "{{{2
  return self._cached_candidates
endfunction




function! ku#source#project#on_source_enter() abort dict "{{{2
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




" Actions  "{{{1
function! ku#source#project#action_open(candidate) abort  "{{{2
  if has_key(a:candidate.user_data, 'ku_file_path')
    cd `=a:candidate.user_data.ku_file_path`
    call ku#start(a:candidate.user_data.ku__source._source)
    return 0
  else
    return 'No such directory: ' . string(a:candidate.word)
  endif
endfunction








" __END__  "{{{1
" vim: foldmethod=marker
