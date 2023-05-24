function! luis#source#mark#new(...) abort
  let source = copy(s:Source)
  let source.bufnr = get(a:000, 0, -1)
  let source.cached_candidates = []
  return source
endfunction

let s:Source = {
\   'name': 'mark',
\   'default_kind': luis#kind#mark#import(),
\ }

function! s:Source.gather_candidates(context) abort dict
  return self.cached_candidates
endfunction

function! s:Source.on_source_enter(context) abort dict
  let candidates = []
  if self.bufnr >= 0
    let bufname = bufname(self.bufnr)
    for mark in getmarklist(self.bufnr)  " buffer local marks
      let mark_name = mark.mark[1:]
      call add(candidates, {
      \   'word': bufname . ':' . mark.pos[1] . ':' . mark.pos[2],
      \   'menu': 'mark ' . mark_name,
      \   'dup': 1,
      \   'user_data': {
      \     'mark_name': mark_name,
      \     'mark_pos': mark.pos[1:2],
      \   },
      \   'luis_sort_priority': char2nr(mark_name),
      \ })
    endfor
  else
    for mark in getmarklist()  " global marks
      let mark_name = mark.mark[1:]
      call add(candidates, {
      \   'word': mark.file . ':' . mark.pos[1] . ':' . mark.pos[2],
      \   'menu': 'mark ' . mark_name,
      \   'dup': 1,
      \   'user_data': {
      \     'mark_name': mark_name,
      \     'mark_pos': mark.pos[1:2],
      \   },
      \   'luis_sort_priority': char2nr(mark_name),
      \ })
    endfor
  endif
  let self.cached_candidates = candidates
endfunction

function! s:Source.preview_candidate(candidate, context) abort
  if self.bufnr >= 0
  \  && has_key(a:candidate.user_data, 'mark_pos')
    return {
    \   'type': 'buffer',
    \   'bufnr': self.bufnr,
    \   'pos': a:candidate.user_data.mark_pos,
    \ }
  else
    return { 'type': 'none' }
  endif
endfunction
