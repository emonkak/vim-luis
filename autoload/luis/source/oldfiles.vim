function! luis#source#oldfiles#new() abort
  let source = copy(s:Source)
  let source._cached_candidates = []
  return source
endfunction

let s:Source = {
\   'name': 'oldfiles',
\   'default_kind': g:luis#kind#file#export,
\   'matcher': g:luis#matcher#default,
\ }

function! s:Source.gather_candidates(args) abort dict
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
    \     'file_path': path,
    \   },
    \   'luis_sort_priority': i,
    \ })
  endfor
  let self._cached_candidates = candidates
endfunction
