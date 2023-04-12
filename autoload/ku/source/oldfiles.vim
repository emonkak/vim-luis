function! ku#source#oldfiles#new() abort
  let source = copy(s:Source)
  let source._cached_candidates = []
  return source
endfunction

let s:Source = {
\   'name': 'oldfiles',
\   'default_kind': g:ku#kind#file#export,
\   'matcher': g:ku#matcher#default,
\ }

function! s:Source.gather_candidates(pattern) abort dict
  return self._cached_candidates
endfunction

function! s:Source.on_source_enter() abort dict
  let candidates = []
  for i in range(len(v:oldfiles))
    let path = v:oldfiles[i]
    if !filereadable(path)
      continue
    endif
    call add(candidates, {
    \   'word': fnamemodify(path, ':~:.'),
    \   'user_data': {
    \     'ku_file_path': path,
    \   },
    \   'ku__sort_priority': i,
    \ })
  endfor
  let self._cached_candidates = candidates
endfunction
