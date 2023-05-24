function! luis#source#fold#new(window) abort
  let source = copy(s:Source)
  let source.window = a:window
  let source.cached_candidates = []
  return source
endfunction

let s:Source = {
\   'name': 'fold',
\   'default_kind': luis#kind#buffer#import(),
\ }

function! s:Source.gather_candidates(context) abort dict
  return self.cached_candidates
endfunction

function! s:Source.on_source_enter(context) abort dict
  let original_window = win_getid()
  let original_lazyredraw = &lazyredraw

  " Suppress redraw during collecting folds.
  set lazyredraw
  " Back to the original buffer.
  noautocmd call win_gotoid(self.window)
  " Duplite the original buffer.
  split

  let bufnr = bufnr('%')
  let candidates = []

  try
    setlocal foldtext&
    normal! zM

    for lnum in range(1, line('$'))
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
          \     'buffer_nr': bufnr,
          \     'buffer_pos': [lnum, 1],
          \   },
          \   'luis_sort_priority': lnum,
          \ })
          execute lnum 'foldopen'
        endif
      endif
    endfor
  finally
    close
    noautocmd call win_gotoid(original_window)
    let &lazyredraw = original_lazyredraw
  endtry

  let self.cached_candidates = candidates
endfunction

function! s:Source.preview_candidate(candidate, context) abort
  if has_key(a:candidate.user_data, 'buffer_nr')
  \  && has_key(a:candidate.user_data, 'buffer_pos')
    return {
    \   'type': 'buffer',
    \   'bufnr': a:candidate.user_data.buffer_nr,
    \   'pos': a:candidate.user_data.buffer_pos,
    \ }
  else
    return { 'type': 'none' }
  endif
endfunction
