" ku source: fold
" Module  "{{{1

let s:SOURCE_TEMPLATE = {
\   'name': 'fold',
\   'kind': {
\     'action_table': {
\       'open': function('ku#source#fold#action_open'),
\     },
\     'key_table': {},
\     'prototype': g:ku#kind#common#module,
\   },
\   'gather_candidates': function('ku#source#fold#gather_candidates'),
\   'matcher': g:ku#matcher#default,
\   'on_action': function('ku#source#default#on_action'),
\   'on_source_enter': function('ku#source#fold#on_source_enter'),
\   'on_source_leave': function('ku#source#default#on_source_leave'),
\   'special_char_p': function('ku#source#default#special_char_p'),
\   'valid_for_acc_p': function('ku#source#default#valid_for_acc_p'),
\ }

function! ku#source#fold#new() abort
  return extend({'_cached_candidates': []}, s:SOURCE_TEMPLATE, 'keep')
endfunction








" Interface  "{{{1
function! ku#source#fold#gather_candidates(pattern) abort dict  "{{{2
  return self._cached_candidates
endfunction




function! ku#source#fold#on_source_enter() abort dict  "{{{2
  let original_winnr = winnr()
  let original_lazyredraw = &lazyredraw
  let original_foldtext = &l:foldtext

  set lazyredraw
  noautocmd wincmd p  " Prevent close *ku* window

  split
  setlocal foldtext&
  normal! zM

  let candidates = []

  let lnum = 1
  while lnum < line('$')
    if foldclosed(lnum) > 0
      let foldtext = foldtextresult(lnum)
      let matches = matchlist(foldtext, '^+-\+\s*\(\d\+\)\slines:\s\zs\(.\{-}\)\ze\s*$')
      if empty(matches)
        continue
      endif
      let num_lines = matches[1]
      let heading = matches[2]
      let indent = repeat(' ', (foldlevel(lnum) - 1) * 2)
      call add(candidates, {
      \   'word': heading,
      \   'abbr': indent . heading,
      \   'menu': num_lines . ' lines',
      \   'dup': 1,
      \   'user_data': {
      \     'ku_fold_lnum': lnum,
      \   },
      \   'ku__sort_priority': lnum,
      \ })
      execute lnum 'foldopen'
    endif
    let lnum += 1
  endwhile

  close
  noautocmd execute original_winnr 'wincmd w'

  let &lazyredraw = original_lazyredraw
  let &l:foldtext = original_foldtext

  let self._cached_candidates = candidates
endfunction








" Actions  "{{{1
function! ku#source#fold#action_open(candidate) abort  "{{{2
  if !has_key(a:candidate.user_data, 'ku_fold_lnum')
    return 'No such fold'
  endif
  call cursor(a:candidate.user_data.ku_fold_lnum, 1)
  normal! zvzt
  return 0
endfunction








" __END__  "{{{1
" vim: foldmethod=marker
