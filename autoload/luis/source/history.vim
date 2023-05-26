function! luis#source#history#new(history_name) abort
  let source = copy(s:Source)
  let source.name = 'history/' . a:history_name
  let source.history_name = a:history_name
  let source.cached_candidates = []
  return source
endfunction

let s:Source = {
\   'default_kind': luis#kind#history#import(),
\ }

function! s:Source.gather_candidates(context) abort dict
  return self.cached_candidates
endfunction

function! s:Source.on_source_enter(context) abort dict
  let candidates = []
  let l = histnr(self.history_name)
  if l > 0
    for i in range(1, l)
      let history = histget(self.history_name, i)
      if history == ''
        continue
      endif
      call add(candidates, {
      \   'word': history,
      \   'menu': 'history ' . i,
      \   'dup': 1,
      \   'user_data': {
      \     'history_index': i,
      \     'history_name': self.history_name,
      \   },
      \   'luis_sort_priority': -i,
      \ })
    endfor
  endif
  let self.cached_candidates = candidates
endfunction
