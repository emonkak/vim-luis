function! luis#source#args#new() abort
  let source = copy(s:Source)
  let source._cached_candidates = []
  return source
endfunction

let s:Source = {
\   'name': 'args',
\   'default_kind': luis#kind#args#import(),
\   'matcher': luis#matcher#default#import(),
\ }

function! s:Source.gather_candidates(context) abort dict
  return self._cached_candidates
endfunction

function! s:Source.on_source_enter(context) abort dict
  let self._cached_candidates = map(argv(), '{ "word": v:val }')
endfunction
