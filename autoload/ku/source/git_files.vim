" ku source: git_files
" Constants  "{{{1

let s:FILE_STATUSES_BY_TAG = {
\   'H': 'cached',
\   'S': 'skip',
\   'M': 'unmerged',
\   'R': 'deleted',
\   'C': 'modified',
\   'K': 'killed',
\ }








" Module  "{{{1

let s:SOURCE_TEMPLATE = {
\   'gather_candidates': function('ku#source#git_files#gather_candidates'),
\   'kind': g:ku#kind#file#module,
\   'name': 'git_files',
\   'on_action': function('ku#source#default#on_action'),
\   'on_source_enter': function('ku#source#git_files#on_source_enter'),
\   'on_source_leave': function('ku#source#default#on_source_leave'),
\   'special_char_p': function('ku#source#default#special_char_p'),
\   'valid_for_acc_p': function('ku#source#default#valid_for_acc_p'),
\ }

function! ku#source#git_files#new() abort
  return extend({'_cached_candidates': []}, s:SOURCE_TEMPLATE, 'keep')
endfunction








" Interface  "{{{1
function! ku#source#git_files#on_source_enter() abort dict "{{{2
  let candidates = []

  let lines = systemlist('git ls-files --exclude-standard -v -c -o')
  if v:shell_error != 0
    return candidates
  endif

  for line in lines
    let [tag, file] = split(line, '^\S\zs\s', 1)
    call add(candidates, {
    \   'word': file,
    \   'menu': s:file_status_from_tag(tag),
    \ })
  endfor

  let self._cached_candidates = candidates
endfunction




function! ku#source#git_files#gather_candidates(pattern) abort dict  "{{{2
  return self._cached_candidates
endfunction








" Misc.   "{{{1
function! s:file_status_from_tag(tag) abort  "{{{2
  return get(s:FILE_STATUSES_BY_TAG, a:tag, 'untracked')
endfunction








" __END__  "{{{1
" vim: foldmethod=marker
