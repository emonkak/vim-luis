function! s:action_Bottom(kind, candidate) abort
  return s:open_with_split(a:kind, 'botright', a:candidate)
endfunction

function! s:action_Left(kind, candidate) abort
  return s:open_with_split(a:kind, 'topleft vertical', a:candidate)
endfunction

function! s:action_Right(kind, candidate) abort
  return s:open_with_split(a:kind, 'botright vertical', a:candidate)
endfunction

function! s:action_Top(kind, candidate) abort
  return s:open_with_split(a:kind, 'topleft', a:candidate)
endfunction

function! s:action_Yank(kind, candidate) abort
  call setreg('"', a:candidate.word, 'l')
  return 0
endfunction

function! s:action_above(kind, candidate) abort
  return s:open_with_split(a:kind, 'leftabove', a:candidate)
endfunction

function! s:action_below(kind, candidate) abort
  return s:open_with_split(a:kind, 'belowright', a:candidate)
endfunction

function! s:action_cancel(kind, candidate) abort
  " Cancel to take actioin - nothing to do.
  return 0
endfunction

function! s:action_default(kind, candidate) abort
  return luis#do_action(a:kind, 'open', a:candidate)
endfunction

function! s:action_ex(kind, candidate) abort
  " Result is ':| {candidate}', here '|' means the cursor position.
  call feedkeys(printf(": %s\<C-b>", fnameescape(a:candidate.word)), 'n')
  return 0
endfunction

function! s:action_left(kind, candidate) abort
  return s:open_with_split(a:kind, 'leftabove vertical', a:candidate)
endfunction

function! s:action_open(kind, candidate) abort
  return 'Action "open" is not defined for this candidate: '
  \      . string(a:candidate)
endfunction

function! s:action_open_x(kind, candidate) abort
  return luis#do_action(a:kind, 'open', a:candidate)
endfunction

function! s:action_put(kind, candidate) abort
  put =a:candidate.word
  return 0
endfunction

function! s:action_put_x(kind, candidate) abort
  put! =a:candidate.word
  return 0
endfunction

function! s:action_reselect(kind, candidate) abort
  call luis#restart()
  return 0
endfunction

function! s:action_right(kind, candidate) abort
  return s:open_with_split(a:kind, 'belowright vertical', a:candidate)
endfunction

function! s:action_tab_Left(kind, candidate) abort
  return s:open_with_split(a:kind, '0 tab', a:candidate)
endfunction

function! s:action_tab_Right(kind, candidate) abort
  return s:open_with_split(a:kind, tabpagenr('$') . ' tab', a:candidate)
endfunction

function! s:action_tab_left(kind, candidate) abort
  return s:open_with_split(a:kind, (tabpagenr() - 1) . ' tab', a:candidate)
endfunction

function! s:action_tab_right(kind, candidate) abort
  return s:open_with_split(a:kind, 'tab', a:candidate)
endfunction

function! s:action_yank(kind, candidate) abort
  call setreg('"', a:candidate.word, 'c')
  return 0
endfunction

function! s:open_with_split(kind, direction, candidate) abort
  let original_tabpagenr = tabpagenr()
  let original_curwinnr = winnr()
  let original_winrestcmd = winrestcmd()

  try
    execute a:direction 'split'
  catch
    return v:exception
  endtry

  let error = luis#do_action(a:kind, 'open', a:candidate)
  if error isnot 0
    " Undo the last :split.
    close
    execute 'tabnext' original_tabpagenr
    execute original_curwinnr 'wincmd w'
    execute original_winrestcmd
    return error
  endif

  return 0
endfunction

let g:luis#kind#common#export = {
\   'name': 'common',
\   'action_table': {
\     'Bottom': function('s:action_Bottom'),
\     'Left': function('s:action_Left'),
\     'Right': function('s:action_Right'),
\     'Top': function('s:action_Top'),
\     'Yank': function('s:action_Yank'),
\     'above': function('s:action_above'),
\     'below': function('s:action_below'),
\     'cancel': function('s:action_cancel'),
\     'default': function('s:action_default'),
\     'ex': function('s:action_ex'),
\     'left': function('s:action_left'),
\     'open!': function('s:action_open_x'),
\     'open': function('s:action_open'),
\     'put!': function('s:action_put_x'),
\     'put': function('s:action_put'),
\     'reselect': function('s:action_reselect'),
\     'right': function('s:action_right'),
\     'tab-Left': function('s:action_tab_Left'),
\     'tab-Right': function('s:action_tab_Right'),
\     'tab-left': function('s:action_tab_left'),
\     'tab-right': function('s:action_tab_right'),
\     'yank': function('s:action_yank'),
\   },
\   'key_table': {
\     "\<C-c>": 'cancel',
\     "\<C-h>": 'left',
\     "\<C-j>": 'below',
\     "\<C-k>": 'above',
\     "\<C-l>": 'right',
\     "\<C-o>": 'open',
\     "\<C-r>": 'reselect',
\     "\<C-t>": 'tab-Right',
\     "\<CR>": 'default',
\     "\<Esc>": 'cancel',
\     ':': 'ex',
\     ';': 'ex',
\     'H': 'Left',
\     'J': 'Bottom',
\     'K': 'Top',
\     'L': 'Right',
\     'O': 'open!',
\     'P': 'put!',
\     'Y': 'Yank',
\     'h': 'left',
\     'j': 'below',
\     'k': 'above',
\     'l': 'right',
\     'o': 'open',
\     'p': 'put',
\     't': 'tab-Right',
\     'y': 'yank',
\   },
\ }
