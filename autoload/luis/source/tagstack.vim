function! luis#source#tagstack#new(window) abort
  let source = copy(s:Source)
  let source.window = a:window
  let source.cached_candidates = []
  return source
endfunction

let s:Source = {
\   'name': 'tagstack',
\   'default_kind': luis#kind#tagstack#import(),
\ }

function! s:Source.gather_candidates(context) abort dict
  return self.cached_candidates
endfunction

function! s:Source.on_source_enter(context) abort dict
  let index = 1  " 1-origin
  let candidates = []

  for item in gettagstack(self.window).items
    let bufname = bufname(item.bufnr)
    call add(candidates, {
    \   'word': item.tagname,
    \   'menu': bufname . ':' . item.from[1] . ':' . item.from[2],
    \   'dup': 1,
    \   'user_data': {
    \     'tagstack_index': index,
    \     'buffer_nr': item.bufnr,
    \     'buffer_cursor': item.from[1:2],
    \     'preview_bufnr': item.bufnr,
    \     'preview_cursor': item.from[1:2],
    \   },
    \   'luis_sort_priority': index,
    \ })
    let index += 1
  endfor

  let self.cached_candidates = candidates
endfunction
