function! luis#source#fold#new() abort
  let source = copy(s:Source)
  let source._cached_candidates = []
  return source
endfunction

function! s:action_open(kind, candidate) abort
  if !has_key(a:candidate.user_data, 'fold_lnum')
    return 'No such fold'
  endif
  call cursor(a:candidate.user_data.fold_lnum, 1)
  normal! zvzt
  return 0
endfunction

let s:Source = {
\   'name': 'fold',
\   'default_kind': {
\     'action_table': {
\       'open': function('s:action_open'),
\     },
\     'key_table': {},
\     'prototype': g:luis#kind#common#export,
\   },
\   'matcher': g:luis#matcher#default,
\ }

function! s:Source.gather_candidates(pattern) abort dict
  return self._cached_candidates
endfunction

function! s:Source.on_source_enter() abort dict
  let original_winnr = winnr()
  let original_lazyredraw = &lazyredraw
  let original_foldtext = &l:foldtext

  set lazyredraw
  noautocmd wincmd p  " Prevent close *luis* window

  split
  setlocal foldtext&
  normal! zM

  let candidates = []

  let lnum = 1
  while lnum < line('$')
    if foldclosed(lnum) > 0
      let foldtext = foldtextresult(lnum)
      let matches = matchlist(foldtext, '^+-\+\s*\(\d\+\)\slines:\s\zs\(.\{-}\)\ze\s*$')
      if len(matches) > 0
        let num_lines = matches[1]
        let heading = matches[2]
        let indent = repeat(' ', (foldlevel(lnum) - 1) * 2)
        call add(candidates, {
        \   'word': heading,
        \   'abbr': indent . heading,
        \   'menu': num_lines . ' lines',
        \   'dup': 1,
        \   'user_data': {
        \     'fold_lnum': lnum,
        \   },
        \   'luis_sort_priority': lnum,
        \ })
        execute lnum 'foldopen'
      endif
    endif
    let lnum += 1
  endwhile

  close
  noautocmd execute original_winnr 'wincmd w'

  let &lazyredraw = original_lazyredraw
  let &l:foldtext = original_foldtext

  let self._cached_candidates = candidates
endfunction
