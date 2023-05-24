function! luis#source#args#new() abort
  let source = copy(s:Source)
  let source.cached_candidates = []
  return source
endfunction

let s:Source = {
\   'name': 'args',
\   'default_kind': luis#kind#args#import(),
\ }

function! s:Source.gather_candidates(context) abort dict
  return self.cached_candidates
endfunction

function! s:Source.on_source_enter(context) abort dict
  let self.cached_candidates = map(argv(), '{
  \   "word": v:val,
  \   "user_data": { "args_index": v:key },
  \ }')
endfunction

function! s:Source.preview_candidate(candidate, context) abort
  let bufnr = bufnr(a:candidate.word)
  if bufnr >= 0
    return { 'type': 'buffer', 'bufnr': bufnr }
  else
    return { 'type': 'none' }
  endif
endfunction
