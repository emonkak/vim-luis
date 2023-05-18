function! luis#source#colorscheme#new() abort
  let source = copy(s:Source)
  let source._cached_candidates = []
  return source
endfunction

let s:Source = {
\   'name': 'colorscheme',
\   'default_kind': luis#kind#colorscheme#import(),
\ }

function! s:Source.gather_candidates(context) abort dict
  return self._cached_candidates
endfunction

function! s:Source.on_source_enter(context) abort dict
  let colorschemes = globpath(&runtimepath, 'colors/*.vim', 0, 1)
  let self._cached_candidates = map(colorschemes, '{
  \   "word": fnamemodify(v:val, ":t:r"),
  \   "menu": fnamemodify(v:val, ":p:h:h"),
  \ }')
endfunction
