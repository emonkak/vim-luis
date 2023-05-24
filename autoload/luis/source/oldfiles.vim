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
  let self.cached_candidates = candidates
endfunction

function! s:Source.preview_candidate(candidate, context) abort
  if filereadable(a:candidate.word)
    let dimensions = a:context.preview_dimensions
    let lines = readfile(a:candidate.word, '', dimensions.height)
    try
      return {
      \   'type': 'text',
      \   'lines': lines,
      \ }
    catch /\<E484:/
      return { 'type': 'text', 'lines': [v:exception] }
    endtry
  else
    return { 'type': 'none' }
  endif
endfunction
