" ku source: file_rec
" Module  "{{{1

let s:SOURCE_TEMPLATE = {
\   'name': 'file_rec',
\   'default_kind': g:ku#kind#file#export,
\   'matcher': g:ku#matcher#default,
\   'gather_candidates': function('ku#source#file_rec#gather_candidates'),
\   'on_action': function('ku#source#file_rec#on_action'),
\   'on_source_enter': function('ku#source#file_rec#on_source_enter'),
\   'on_source_leave': function('ku#source#file_rec#on_source_leave'),
\   'special_char_p': function('ku#source#file_rec#special_char_p'),
\   'valid_for_acc_p': function('ku#source#file_rec#valid_for_acc_p'),
\   '_cached_candidates': []
\ }

function! ku#source#file_rec#new(limit_files) abort
  return extend({
  \   '_limit_files': a:limit_files,
  \   '_source': ku#source#file#new(),
  \ }, s:SOURCE_TEMPLATE, 'keep')
endfunction








" Interface  "{{{1
function! ku#source#file_rec#gather_candidates(pattern) dict abort  "{{{2
  let all_candidates = []
  let pending_candidates = [{ 'abbr': a:pattern }]

  while 1
    let pattern = remove(pending_candidates, 0).abbr
    for candidate in self._source.gather_candidates(pattern)
      call add(candidate.ku_is_direcotry ? pending_candidates : all_candidates,
      \        candidate)
    endfor
    if empty(pending_candidates)
    \  || len(all_candidates) + len(pending_candidates) >= self._limit_files
      break
    endif
  endwhile

  return extend(all_candidates, pending_candidates)
endfunction




function! ku#source#file_rec#on_action(candidate) dict abort  "{{{2
  return self._source.on_action(a:candidate)
endfunction




function! ku#source#file_rec#on_source_enter() dict abort  "{{{2
  call self._source.on_source_enter()
endfunction




function! ku#source#file_rec#on_source_leave() dict abort  "{{{2
  call self._source.on_source_leave()
endfunction




function! ku#source#file_rec#special_char_p(char) dict abort  "{{{2
  return self._source.special_char_p(a:char)
endfunction




function! ku#source#file_rec#valid_for_acc_p(candidate, sep) dict abort  "{{{2
  return self._source.valid_for_acc_p(a:candidate, a:sep)
endfunction








" __END__  "{{{1
" vim: foldmethod=marker
