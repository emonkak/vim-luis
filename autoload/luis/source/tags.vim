function! luis#source#tags#new(tag_files) abort
  let source = copy(s:Source)
  let source._tag_files = a:tag_files
  let source._cached_candidates = []
  return source
endfunction

let s:Source = {
\   'name': 'tags',
\   'default_kind': luis#kind#tag#import(),
\ }

function! s:Source.gather_candidates(context) abort dict
  return self._cached_candidates
endfunction

function! s:Source.on_source_enter(context) abort dict
  let candidates = []

  for tag_file in self._tag_files
    let lines = readfile(tag_file)
    for line in lines 
      let components = split(line, '\t')
      if len(components) < 2
        continue
      endif
      let [name, file; _] = components
      call add(candidates, {
      \   'word': name,
      \   'menu': file,
      \   'dup': 1,
      \ })
    endfor
  endfor

  let self._cached_candidates = candidates
endfunction
