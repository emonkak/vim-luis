function! luis#source#jumplist#new(window) abort
  let source = copy(s:Source)
  let source.window = a:window
  let source.cached_candidates = []
  return source
endfunction

let s:Source = {
\   'name': 'jumplist',
\   'default_kind': luis#kind#buffer#import(),
\ }

function! s:Source.gather_candidates(context) abort dict
  return self.cached_candidates
endfunction

function! s:Source.on_source_enter(context) abort dict
  let candidates = []
  let [locations, position] = getjumplist(self.window)
  let l = len(locations)
  for i in range(l - 1, 0, -1)
    let location = locations[i]
    let bufname = bufname(location.bufnr)
    call add(candidates, {
    \   'word': bufname . ':' . location.lnum . ':' . location.col,
    \   'menu': 'jump ' . (l - i),
    \   'dup': 1,
    \   'user_data': {
    \     'buffer_nr': location.bufnr,
    \     'buffer_pos': [location.lnum, location.col],
    \   },
    \   'luis_sort_priority': l - i,
    \ })
  endfor
  let self.cached_candidates = candidates
endfunction

function! s:Source.preview_candidate(candidate, context) abort
  if has_key(a:candidate.user_data, 'buffer_nr')
  \  && has_key(a:candidate.user_data, 'buffer_pos')
    return {
    \   'type': 'buffer',
    \   'bufnr': a:candidate.user_data.buffer_nr,
    \   'lnum': a:candidate.user_data.buffer_pos[0],
    \ }
  else
    return { 'type': 'none' }
  endif
endfunction
