function! luis#source#fold#new(window) abort
  let source = copy(s:Source)
  let source._window = a:window
  let source._cached_candidates = []
  return source
endfunction

let s:Source = {
\   'name': 'fold',
\   'default_kind': luis#kind#buffer#import(),
\ }

function! s:Source.gather_candidates(context) abort dict
  return self._cached_candidates
endfunction

function! s:Source.on_source_enter(context) abort dict
  let original_window = win_getid()
  let original_lazyredraw = &lazyredraw

  " Suppress the redrawing during collecting folds.
  set lazyredraw
  " Go to the target window.
  noautocmd call win_gotoid(self._window)
  " Duplicate the target window.
  split
  " Update and close folds.
  normal! zxzM

  let bufnr = winbufnr(self._window)
  let candidates = []

  try
    for lnum in range(1, line('$'))
      let foldstart = foldclosed(lnum)
      if foldstart > 0
        let foldtext = s:remove_foldtext_decorations(foldtextresult(lnum))
        let foldend = foldclosedend(lnum)
        let indent = repeat(' ', (foldlevel(lnum) - 1) * 2)
        call add(candidates, {
        \   'word': foldtext,
        \   'abbr': indent . foldtext,
        \   'menu': (foldend - foldstart + 1) . ' lines',
        \   'dup': 1,
        \   'user_data': {
        \     'buffer_nr': bufnr,
        \     'buffer_cursor': [lnum, 1],
        \     'preview_bufnr': bufnr,
        \     'preview_cursor': [lnum, 1],
        \   },
        \   'luis_sort_priority': lnum,
        \ })
        execute lnum 'foldopen'
      endif
    endfor
  finally
    close
    noautocmd call win_gotoid(original_window)
    let &lazyredraw = original_lazyredraw
  endtry

  let self._cached_candidates = candidates
endfunction

function! s:remove_foldtext_decorations(foldtext) abort
  return substitute(
  \   a:foldtext,
  \   '^+\?-*\%( *\d\+ lines:\)\?\s\+\|\s\+$',
  \   '',
  \   'g'
  \ )
endfunction
