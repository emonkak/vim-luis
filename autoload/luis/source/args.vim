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
  let argidx = argidx()
  let self.cached_candidates = map(argv(), '{
  \   "word": v:val,
  \   "kind": v:key == argidx ? "*" : "",
  \   "user_data": { "args_index": v:key, "preview_bufnr": bufnr(v:val) },
  \   "luis_sort_priority": -v:key,
  \ }')
endfunction
