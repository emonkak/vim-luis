" ku source: metarw
" Module  "{{{1

let s:SOURCE_TEMPLATE = {
\   'default_kind': g:ku#kind#file#module,
\   'matcher': g:ku#matcher#default,
\   'gather_candidates': function('ku#source#metarw#gather_candidates'),
\   'on_action': function('ku#source#metarw#on_action'),
\   'on_source_enter': function('ku#source#default#on_source_enter'),
\   'on_source_leave': function('ku#source#default#on_source_leave'),
\   'special_char_p': function('ku#source#metarw#special_char_p'),
\   'valid_for_acc_p': function('ku#source#default#valid_for_acc_p'),
\ }

function! ku#source#metarw#new(scheme) abort
  return extend({
  \   'name': 'metarw/' . a:scheme,
  \   '_scheme': a:scheme,
  \ }, s:SOURCE_TEMPLATE, 'keep')
endfunction








" Interface  "{{{1
function! ku#source#metarw#gather_candidates(pattern) abort dict  "{{{2
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
    \   }
    \ })
  endfor

  return candidates
endfunction




function! ku#source#metarw#on_action(candidate) abort dict  "{{{2
  let candidate = copy(a:candidate)
  let candidate.ku_file_path = self._scheme . ':' . a:candidate.word
  return candidate
endfunction




function! ku#source#metarw#special_char_p(char) abort dict  "{{{2
  return a:char == s:path_separator() || a:char == ':'
endfunction








" Misc.  "{{{1
function! s:path_separator() abort  "{{{2
  return (exists('+shellslash') && !&shellslash) ? '\' : '/'
endfunction








" __END__  "{{{1
" vim: foldmethod=marker
