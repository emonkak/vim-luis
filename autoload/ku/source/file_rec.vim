function! ku#source#file_rec#new(limit) abort
  let source = copy(s:Source)
  let source._cached_candidates = []
  let source._limit = a:limit
  let source._source = ku#source#file#new()
  return source
endfunction

let s:Source = {
\   'name': 'file_rec',
\   'default_kind': g:ku#kind#file#export,
\   'matcher': g:ku#matcher#default,
\ }

function! s:Source.gather_candidates(pattern) dict abort
  let all_candidates = []
  let pending_candidates = [{ 'abbr': a:pattern }]

  while 1
    let pattern = remove(pending_candidates, 0).abbr
    for candidate in self._source.gather_candidates(pattern)
      call add(candidate.ku_directory_p ? pending_candidates : all_candidates,
      \        candidate)
    endfor
    if empty(pending_candidates)
    \  || len(all_candidates) + len(pending_candidates) >= self._limit
      break
    endif
  endwhile

  return extend(all_candidates, pending_candidates)
endfunction

function! s:Source.on_action(candidate) dict abort
  return self._source.on_action(a:candidate)
endfunction

function! s:Source.on_source_enter() dict abort
  call self._source.on_source_enter()
endfunction

function! s:Source.on_source_leave() dict abort
  call self._source.on_source_leave()
endfunction

function! s:Source.special_char_p(char) dict abort
  return self._source.special_char_p(a:char)
endfunction

function! s:Source.valid_for_acc_p(candidate, sep) dict abort
  return self._source.valid_for_acc_p(a:candidate, a:sep)
endfunction
