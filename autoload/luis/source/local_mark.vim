function! luis#source#local_mark#new(bufnr) abort
  let source = copy(s:Source)
  let source.bufnr = a:bufnr
  let source.cached_candidates = []
  return source
endfunction

let s:Source = {
\   'name': 'local_mark',
\   'default_kind': luis#kind#mark#import(),
\ }

function! s:Source.gather_candidates(context) abort dict
  return self.cached_candidates
endfunction

function! s:Source.on_source_enter(context) abort dict
  let candidates = []
  let bufname = bufname(self.bufnr)
  for mark in getmarklist(self.bufnr)
    let mark_name = mark.mark[1:]
    call add(candidates, {
    \   'word': bufname . ':' . mark.pos[1] . ':' . mark.pos[2],
    \   'menu': 'mark ' . mark_name,
    \   'dup': 1,
    \   'user_data': {
    \     'mark_name': mark_name,
    \     'mark_pos': mark.pos[1:2],
    \     'preview_bufnr': self.bufnr,
    \     'preview_cursor': mark.pos[1:2],
    \   },
    \   'luis_sort_priority': -char2nr(mark_name),
    \ })
  endfor
  let self.cached_candidates = candidates
endfunction
