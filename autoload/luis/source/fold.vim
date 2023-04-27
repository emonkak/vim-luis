function! luis#source#fold#new() abort
  let source = copy(s:Source)
  let source._cached_candidates = []
  return source
endfunction

let s:Source = {
\   'name': 'fold',
\   'default_kind': g:luis#kind#fold#export,
\   'matcher': g:luis#matcher#default,
\ }

function! s:Source.gather_candidates(args) abort dict
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
  let max_lnum = line('$')

  while lnum < max_lnum
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
