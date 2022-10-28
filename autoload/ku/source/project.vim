" ku source: project
" Module  "{{{1

let s:SOURCE_TEMPLATE = {
\   'name': 'project',
\   'kind': {
\     'action_table': {
\       'open': function('ku#source#project#action_open'),
\     },
\     'key_table': {},
\     'prototype': g:ku#kind#common#module,
\   },
\   'matcher': g:ku#matcher#default,
\   'gather_candidates': function('ku#source#project#gather_candidates'),
\   'on_action': function('ku#source#default#on_action'),
\   'on_source_enter': function('ku#source#project#on_source_enter'),
\   'on_source_leave': function('ku#source#default#on_source_leave'),
\   'special_char_p': function('ku#source#default#special_char_p'),
\   'valid_for_acc_p': function('ku#source#default#valid_for_acc_p'),
\ }

function! ku#source#project#new(project_directory) abort
  return extend({
  \   '_cached_candidates': [],
  \   '_project_directory': a:project_directory,
  \ }, s:SOURCE_TEMPLATE, 'keep')
endfunction








" Interface  "{{{1
function! ku#source#project#gather_candidates(pattern) abort dict "{{{2
  return self._cached_candidates
endfunction




function! ku#source#project#on_source_enter() abort dict "{{{2
  let candidates = []
  for path in globpath(self._project_directory, '*', 0, 1)
    if !isdirectory(path)
      continue
    endif
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
function! ku#source#project#action_open(candidate)  "{{{2
  if has_key(a:candidate, 'user_data')
  \  && has_key(a:candidate.user_data, 'ku_file_path')
    cd `=a:candidate.user_data.ku_file_path`
    call ku#start(ku#source#file#new())
    return 0
  else
    return 'No such directory: ' . string(a:candidate.word)
  endif
endfunction








" __END__  "{{{1
" vim: foldmethod=marker
