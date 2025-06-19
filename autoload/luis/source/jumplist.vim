function! luis#source#jumplist#new(window) abort
  let source = copy(s:Source)
  let source._window = a:window
  let source._cached_candidates = []
  return source
endfunction

let s:Source = {
\   'name': 'jumplist',
\   'default_kind': luis#kind#jumplist#import(),
\ }

function! s:Source.gather_candidates(context) abort dict
  return self._cached_candidates
endfunction

function! s:Source.on_source_enter(context) abort dict
  let jumplist = getjumplist(self._window)
  if empty(jumplist)
    return
  endif
  let [locations, current_location] = jumplist
  let candidates = []
  for i in range(len(locations))
    let location = locations[i]
    let bufname = bufname(location.bufnr)
    call add(candidates, {
    \   'word': bufname . ':' . location.lnum . ':' . location.col,
    \   'menu': 'jump ' . (i + 1),
    \   'kind': i == current_location ? '*' : '',
    \   'dup': 1,
    \   'user_data': {
    \     'buffer_nr': location.bufnr,
    \     'buffer_cursor': [location.lnum, location.col],
    \     'jumplist_index': i,
    \     'jumplist_window': self._window,
    \     'preview_bufnr': location.bufnr,
    \     'preview_cursor': [location.lnum, location.col],
    \   },
    \   'luis_sort_priority': i,
    \ })
  endfor
  let self._cached_candidates = candidates
endfunction
