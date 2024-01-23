function! luis#source#tagstack#new(window) abort
  let source = copy(s:Source)
  let source._window = a:window
  let source._cached_candidates = []
  return source
endfunction

let s:Source = {
\   'name': 'tagstack',
\   'default_kind': luis#kind#tagstack#import(),
\ }

function! s:Source.gather_candidates(context) abort dict
  return self._cached_candidates
endfunction

function! s:Source.on_source_enter(context) abort dict
  let candidates = []
  let tagstack = gettagstack(self._window)

  for i in range(len(tagstack.items))
    let item = tagstack.items[i]
    if !bufexists(item.bufnr)
      continue
    endif
    let bufname = bufname(item.bufnr)
    call add(candidates, {
    \   'word': item.tagname,
    \   'menu': bufname . ':' . item.from[1] . ':' . item.from[2],
    \   'kind': tagstack.curidx == i + 1 ? '*' : '',
    \   'dup': 1,
    \   'user_data': {
    \     'tagstack_index': i + 1,
    \     'buffer_nr': item.bufnr,
    \     'buffer_cursor': item.from[1:2],
    \     'preview_bufnr': item.bufnr,
    \     'preview_cursor': item.from[1:2],
    \   },
    \   'luis_sort_priority': -i,
    \ })
  endfor

  let self._cached_candidates = candidates
endfunction
