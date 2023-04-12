function! ku#source#file_rec#new(limit) abort
  let source = copy(s:Source)
  let source._cached_candidates = []
  let source._limit = a:limit
  let source._file = ku#source#file#new()
  return source
endfunction

let s:Source = {
\   'name': 'file_rec',
\   'default_kind': g:ku#kind#file#export,
\   'matcher': g:ku#matcher#default,
\ }

function! s:Source.gather_candidates(pattern) dict abort
  let file_candidates = []
  let directory_candidates = []
  let pattern = a:pattern

  while 1
    for candidate in self._file.gather_candidates(pattern)
      let candidates = candidate._is_directory
      \              ? directory_candidates
      \              : file_candidates
      call add(candidates, candidate)
    endfor
    if empty(directory_candidates) > 0
    \  || len(file_candidates) + len(directory_candidates) >= self._limit
      break
    endif
    let pattern = remove(directory_candidates, 0).abbr
  endwhile

  return extend(file_candidates, directory_candidates)
endfunction

function! s:Source.on_action(candidate) dict abort
  return self._file.on_action(a:candidate)
endfunction

function! s:Source.on_file_enter() dict abort
  call self._file.on_source_enter()
endfunction

function! s:Source.on_file_leave() dict abort
  call self._file.on_source_leave()
endfunction

function! s:Source.special_char_p(char) dict abort
  return self._file.special_char_p(a:char)
endfunction

function! s:Source.valid_for_acc_p(candidate, sep) dict abort
  return self._file.valid_for_acc_p(a:candidate, a:sep)
endfunction
