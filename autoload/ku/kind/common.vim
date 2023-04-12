let g:ku#kind#common#export = {
\   'action_table': {
\     'Bottom': function('ku#kind#common#action_Bottom'),
\     'Left': function('ku#kind#common#action_Left'),
\     'Right': function('ku#kind#common#action_Right'),
\     'Top': function('ku#kind#common#action_Top'),
\     'Yank': function('ku#kind#common#action_Yank'),
\     'above': function('ku#kind#common#action_above'),
\     'below': function('ku#kind#common#action_below'),
\     'cancel': function('ku#kind#common#action_cancel'),
\     'default': function('ku#kind#common#action_default'),
\     'ex': function('ku#kind#common#action_ex'),
\     'left': function('ku#kind#common#action_left'),
\     'open!': function('ku#kind#common#action_open_x'),
\     'open': function('ku#kind#common#action_open'),
\     'right': function('ku#kind#common#action_right'),
\     'select': function('ku#kind#common#action_select'),
\     'tab-Left': function('ku#kind#common#action_tab_Left'),
\     'tab-Right': function('ku#kind#common#action_tab_Right'),
\     'tab-left': function('ku#kind#common#action_tab_left'),
\     'tab-right': function('ku#kind#common#action_tab_right'),
\     'yank': function('ku#kind#common#action_yank'),
\   },
\   'key_table': {
\     "\<C-c>": 'cancel',
\     "\<C-h>": 'left',
\     "\<C-j>": 'below',
\     "\<C-k>": 'above',
\     "\<C-l>": 'right',
\     "\<C-o>": 'open',
\     "\<C-r>": 'select',
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
\     'Y': 'Yank',
\     'h': 'left',
\     'j': 'below',
\     'k': 'above',
\     'l': 'right',
\     'o': 'open',
\     't': 'tab-Right',
\     'y': 'yank',
\   },
\ }

function! ku#kind#common#action_Bottom(candidate) abort
  return s:open_with_split('botright', a:candidate)
endfunction

function! ku#kind#common#action_Left(candidate) abort
  return s:open_with_split('topleft vertical', a:candidate)
endfunction

function! ku#kind#common#action_Right(candidate) abort
  return s:open_with_split('botright vertical', a:candidate)
endfunction

function! ku#kind#common#action_Top(candidate) abort
  return s:open_with_split('topleft', a:candidate)
endfunction

function! ku#kind#common#action_Yank(candidate) abort
  call setreg('"', a:candidate.word, 'l')
  return 0
endfunction

function! ku#kind#common#action_above(candidate) abort
  return s:open_with_split('leftabove', a:candidate)
endfunction

function! ku#kind#common#action_below(candidate) abort
  return s:open_with_split('belowright', a:candidate)
endfunction

function! ku#kind#common#action_cancel(candidate) abort
  " Cancel to take actioin - nothing to do.
  return 0
endfunction

function! ku#kind#common#action_default(candidate) abort
  return ku#_do_action('open', a:candidate)
endfunction

function! ku#kind#common#action_ex(candidate) abort
  " Resultl is ':| {candidate}', here '|' means the cursor position.
  call feedkeys(printf(": %s\<C-b>", fnameescape(a:candidate.word)), 'n')
  return 0
endfunction

function! ku#kind#common#action_left(candidate) abort
  return s:open_with_split('leftabove vertical', a:candidate)
endfunction

function! ku#kind#common#action_open(candidate) abort
  return 'Action "open" is not defined for this candidate: '
  \      . string(a:candidate)
endfunction

function! ku#kind#common#action_open_x(candidate) abort
  return ku#_do_action('open', a:candidate)
endfunction

function! ku#kind#common#action_right(candidate) abort
  return s:open_with_split('belowright vertical', a:candidate)
endfunction

function! ku#kind#common#action_select(candidate) abort
  call ku#restart()
  return 0
endfunction

function! ku#kind#common#action_tab_Left(candidate) abort
  return s:open_with_split('0 tab', a:candidate)
endfunction

function! ku#kind#common#action_tab_Right(candidate) abort
  return s:open_with_split(tabpagenr('$') . ' tab', a:candidate)
endfunction

function! ku#kind#common#action_tab_left(candidate) abort
  return s:open_with_split((tabpagenr() - 1) . ' tab', a:candidate)
endfunction

function! ku#kind#common#action_tab_right(candidate) abort
  return s:open_with_split('tab', a:candidate)
endfunction

function! ku#kind#common#action_yank(candidate) abort
  call setreg('"', a:candidate.word, 'c')
  return 0
endfunction

function! s:open_with_split(direction, candidate) abort
  let original_tabpagenr = tabpagenr()
  let original_curwinnr = winnr()
  let original_winrestcmd = winrestcmd()

  let v:errmsg = ''
  silent! execute a:direction 'split'
  if v:errmsg != ''
    return v:errmsg
  endif

  let _ = ku#_do_action('open', a:candidate)

  if _ is 0
    return 0
  else
    " Undo the last :split.
    close
    execute 'tabnext' original_tabpagenr
    execute original_curwinnr 'wincmd w'
    execute original_winrestcmd
    return _
  endif
endfunction
