function! luis#source#history#new(history_name) abort
  let source = copy(s:Source)
  let source.name = 'history/' . a:history_name
  let source._history_name = a:history_name
  let source._cached_candidates = []
  return source
endfunction

let s:Source = {
\   'default_kind': g:luis#kind#history#export,
\   'matcher': g:luis#matcher#default,
\ }

function! s:Source.gather_candidates(context) abort dict
  return self._cached_candidates
endfunction

function! s:Source.on_source_enter() abort dict
  let candidates = []
  let l = histnr(self._history_name)
  if l > 0
    for i in range(1, l)
      let history = histget(self._history_name, i)
      if history == ''
        continue
      endif
      call add(candidates, {
      \   'word': history,
      \   'menu': 'history ' . i,
      \   'dup': 1,
      \   'user_data': {
      \     'history_index': i,
      \     'history_name': self._history_name,
      \   },
      \   'luis_sort_priority': i,
      \ })
    endfor
  endif
  let self._cached_candidates = candidates
endfunction
