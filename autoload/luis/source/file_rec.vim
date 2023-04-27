function! luis#source#file_rec#new(limit) abort
  let source = copy(s:Source)
  let source._cached_candidates = []
  let source._limit = a:limit
  let source._file = luis#source#file#new()
  return source
endfunction

let s:Source = {
\   'name': 'file_rec',
\   'default_kind': g:luis#kind#file#export,
\   'matcher': g:luis#matcher#default,
\ }

function! s:Source.gather_candidates(args) dict abort
  let file_candidates = []
  let directory_candidates = []
  let args = a:args

  while 1
    for candidate in self._file.gather_candidates(args)
      let candidates = candidate._is_directory
      \              ? directory_candidates
      \              : file_candidates
      call add(candidates, candidate)
    endfor
    if empty(directory_candidates) > 0
    \  || len(file_candidates) + len(directory_candidates) >= self._limit
      break
    endif
    let args = extend(copy(args), {
    \   'pattern': remove(directory_candidates, 0).abbr,
    \ })
  endwhile

  return extend(file_candidates, directory_candidates)
endfunction

function! s:Source.is_special_char(char) dict abort
  return self._file.is_special_char(a:char)
endfunction

function! s:Source.is_valid_for_acc(candidate, sep) dict abort
  return self._file.is_valid_for_acc(a:candidate, a:sep)
endfunction

function! s:Source.on_action(candidate) dict abort
  call self._file.on_action(a:candidate)
endfunction

function! s:Source.on_source_enter() dict abort
  call self._file.on_source_enter()
endfunction

function! s:Source.on_source_leave() dict abort
  call self._file.on_source_leave()
endfunction
