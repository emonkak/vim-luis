function! luis#source#metarw#new(scheme) abort
  let source = copy(s:Source)
  let source.name = 'metarw/' . a:scheme
  let source._scheme = a:scheme
  return source
endfunction

let s:Source = {
\   'default_kind': luis#kind#file#import(),
\ }

function! s:Source.gather_candidates(context) abort dict
  let scheme = self._scheme
  let pattern = scheme . ':' . a:context.pattern
  let candidates = []

  for path in metarw#{scheme}#complete(pattern, pattern, 0)[0]
    let path_without_scheme = matchstr(path, '^\h\w*:\zs.*$')
    call add(candidates, {
    \   'word': s:trim_separator(path_without_scheme),
    \   'abbr': path_without_scheme,
    \   'user_data': {
    \     'file_path': path,
    \   },
    \ })
  endfor

  return candidates
endfunction

function! s:Source.is_component_separator(char) abort dict
  return a:char == s:path_separator() || a:char == ':'
endfunction

function! s:Source.is_valid_for_acc(candidate) abort dict
  return get(a:candidate, 'abbr', '') =~# '[/:\\]$'
endfunction

function! s:Source.on_action(candidate, context) abort dict
  if !has_key(a:candidate.user_data, 'file_path')
    let a:candidate.user_data.file_path = self._scheme
    \                                   . ':'
    \                                   . a:candidate.word
  endif
endfunction

function! s:path_separator() abort
  return exists('+shellslash') && !&shellslash ? '\' : '/'
endfunction

function! s:trim_separator(path) abort
  return substitute(a:path, '[/:\\]$', '', '')
endfunction
