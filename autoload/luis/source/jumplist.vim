function! luis#source#jumplist#new() abort
  let source = copy(s:Source)
  let source._cached_candidates = []
  return source
endfunction

let s:Source = {
\   'name': 'jumplist',
\   'default_kind': g:luis#kind#buffer#export,
\   'matcher': g:luis#matcher#default#export,
\ }

function! s:Source.gather_candidates(context) abort dict
  return self._cached_candidates
endfunction

function! s:Source.on_source_enter() abort dict
  let candidates = []
  let last_winnr = winnr('#')
  let [locations, position] = getjumplist(last_winnr)
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
  let self._cached_candidates = candidates
endfunction
