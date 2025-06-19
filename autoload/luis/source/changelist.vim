function! luis#source#changelist#new(bufnr) abort
  let source = copy(s:Source)
  let source._bufnr = a:bufnr
  let source._cached_candidates = []
  return source
endfunction

let s:Source = {
\   'name': 'changelist',
\   'default_kind': luis#kind#changelist#import(),
\ }

function! s:Source.gather_candidates(context) abort dict
  return self._cached_candidates
endfunction

function! s:Source.on_source_enter(context) abort dict
  let changelist = getchangelist(self._bufnr)
  if empty(changelist)
    return
  endif
  let candidates = []
  let [locations, current_location] = changelist
  for i in range(len(locations))
    let location = locations[i]
    let bufname = bufname(self._bufnr)
    call add(candidates, {
    \   'word': bufname . ':' . location.lnum . ':' . location.col,
    \   'menu': 'change ' . (i + 1),
    \   'kind': i == current_location ? '*' : '',
    \   'dup': 1,
    \   'user_data': {
    \     'buffer_nr': self._bufnr,
    \     'buffer_cursor': [location.lnum, location.col],
    \     'changelist_index': i,
    \     'changelist_bufnr': self._bufnr,
    \     'preview_bufnr': self._bufnr,
    \     'preview_cursor': [location.lnum, location.col],
    \   },
    \   'luis_sort_priority': i,
    \ })
  endfor
  let self._cached_candidates = candidates
endfunction
