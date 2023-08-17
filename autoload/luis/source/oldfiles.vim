function! luis#source#oldfiles#new() abort
  let source = copy(s:Source)
  let source.cached_candidates = []
  return source
endfunction

let s:Source = {
\   'name': 'oldfiles',
\   'default_kind': luis#kind#file#import(),
\ }

function! s:Source.gather_candidates(context) abort dict
  return self.cached_candidates
endfunction

function! s:Source.on_source_enter(context) abort dict
  let candidates = []
  for i in range(len(v:oldfiles))
    let path = fnamemodify(v:oldfiles[i], ':p')
    if !filereadable(path)
      continue
    endif
    call add(candidates, {
    \   'word': fnamemodify(path, ':~:.'),
    \   'user_data': {
    \     'file_path': path,
    \     'preview_path': path,
    \   },
    \   'luis_sort_priority': -i,
    \ })
  endfor
  let self.cached_candidates = candidates
endfunction
