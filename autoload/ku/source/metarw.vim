function! ku#source#metarw#new(scheme) abort
  let source = copy(s:Source)
  let source.name = 'metarw/' . a:scheme
  let source._scheme = a:scheme
  return source
endfunction

let s:Source = {
\   'default_kind': g:ku#kind#file#export,
\   'matcher': g:ku#matcher#default,
\ }

function! s:Source.gather_candidates(pattern) abort dict
  " FIXME: caching - but each scheme may already do caching.
  " a:pattern is not always prefixed with "{scheme}:".
  let scheme = self._scheme
  let pattern = scheme . ':' . a:pattern
  let candidates = []

  for path in metarw#{scheme}#complete(pattern, pattern, 0)[0]
    let path_without_scheme = matchstr(path, '^' . scheme . ':\zs.*$')
    call add(candidates, {
    \   'word': trim(path_without_scheme, ':/', 2),
    \   'abbr': path_without_scheme,
    \   'user_data': {
    \     'ku_file_path': path,
    \   },
    \ })
  endfor

  return candidates
endfunction

function! s:Source.on_action(candidate) abort dict
  if !has_key(a:candidate.user_data, 'ku_file_path')
    let a:candidate.user_data.ku_file_path = self._scheme . ':' . a:candidate.word
  endif
  return a:candidate
endfunction

function! s:Source.special_char_p(char) abort dict
  return a:char == s:path_separator() || a:char == ':'
endfunction

function! s:path_separator() abort
  return (exists('+shellslash') && !&shellslash) ? '\' : '/'
endfunction
