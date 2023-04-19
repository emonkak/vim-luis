function! luis#source#args#new() abort
  let source = copy(s:Source)
  let source._cached_candidates = []
  return source
endfunction

let s:Source = {
\   'name': 'args',
\   'default_kind': g:luis#kind#args#export,
\   'matcher': g:luis#matcher#default,
\ }

function! s:Source.gather_candidates(pattern) abort dict
  return self._cached_candidates
endfunction

function! s:Source.on_source_enter() abort dict
  let self._cached_candidates = map(argv(), '{ "word": v:val }')
endfunction