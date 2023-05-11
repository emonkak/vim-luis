function! luis#source#mark#new() abort
  let source = copy(s:Source)
  let source._cached_candidates = []
  return source
endfunction

let s:Source = {
\   'name': 'mark',
\   'default_kind': g:luis#kind#mark#export,
\   'matcher': g:luis#matcher#default#export,
\ }

function! s:Source.gather_candidates(context) abort dict
  return self._cached_candidates
endfunction

function! s:Source.on_source_enter() abort dict
  let candidates = []
  let bufnr = winbufnr(winnr('#'))
  let bufname = bufname(bufnr)
  for mark in getmarklist(bufnr)  " buffer local marks
    let mark_name = mark.mark[1:]
    call add(candidates, {
    \   'word': bufname . ':' . mark.pos[1] . ':' . mark.pos[2],
    \   'menu': 'mark ' . mark_name,
    \   'dup': 1,
    \   'user_data': {
    \     'mark_name': mark_name,
    \   },
    \   'luis_sort_priority': char2nr(mark_name),
    \ })
  endfor
  for mark in getmarklist()  " global marks
    let mark_name = mark.mark[1:]
    call add(candidates, {
    \   'word': mark.file . ':' . mark.pos[1] . ':' . mark.pos[2],
    \   'menu': 'mark ' . mark_name,
    \   'dup': 1,
    \   'user_data': {
    \     'mark_name': mark_name,
    \   },
    \   'luis_sort_priority': char2nr(mark_name),
    \ })
  endfor
  let self._cached_candidates = candidates
endfunction
