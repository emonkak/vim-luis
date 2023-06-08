function! luis#kind#common#import() abort
  return s:Kind
endfunction

function! s:action_Bottom(candidate, context) abort
  return s:open_with_split('botright', a:candidate, a:context)
endfunction

function! s:action_Left(candidate, context) abort
  return s:open_with_split('topleft vertical', a:candidate, a:context)
endfunction

function! s:action_Right(candidate, context) abort
  return s:open_with_split('botright vertical', a:candidate, a:context)
endfunction

function! s:action_Top(candidate, context) abort
  return s:open_with_split('topleft', a:candidate, a:context)
endfunction

function! s:action_Yank(candidate, context) abort
  call setreg('"', a:candidate.word, 'l')
  return 0
endfunction

function! s:action_above(candidate, context) abort
  return s:open_with_split('leftabove', a:candidate, a:context)
endfunction

function! s:action_below(candidate, context) abort
  return s:open_with_split('belowright', a:candidate, a:context)
endfunction

function! s:action_cancel(candidate, context) abort
  " Cancel to take actioin - nothing to do.
  return 0
endfunction

function! s:action_default(candidate, context) abort
  return luis#do_action('open', a:candidate, a:context)
endfunction

function! s:action_ex(candidate, context) abort
  " Result is ':| {candidate}', here '|' means the cursor position.
  call feedkeys(printf(": %s\<C-b>", fnameescape(a:candidate.word)), 'n')
  return 0
endfunction

function! s:action_left(candidate, context) abort
  return s:open_with_split('leftabove vertical', a:candidate, a:context)
endfunction

function! s:action_open(candidate, context) abort
  return 'Action "open" is not defined for this candidate: '
  \      . string(a:candidate)
endfunction

function! s:action_open_x(candidate, context) abort
  return luis#do_action('open', a:candidate, a:context)
endfunction

function! s:action_put(candidate, context) abort
  put =a:candidate.word
  return 0
endfunction

function! s:action_put_x(candidate, context) abort
  put! =a:candidate.word
  return 0
endfunction

function! s:action_reselect(candidate, context) abort
  call a:context.session.start()
  return 0
endfunction

function! s:action_right(candidate, context) abort
  return s:open_with_split('belowright vertical', a:candidate, a:context)
endfunction

function! s:action_tab_Left(candidate, context) abort
  return s:open_with_split('0 tab', a:candidate, a:context)
endfunction

function! s:action_tab_Right(candidate, context) abort
  return s:open_with_split(tabpagenr('$') . ' tab', a:candidate, a:context)
endfunction

function! s:action_tab_left(candidate, context) abort
  return s:open_with_split((tabpagenr() - 1) . ' tab', a:candidate, a:context)
endfunction

function! s:action_tab_right(candidate, context) abort
  return s:open_with_split('tab', a:candidate, a:context)
endfunction

function! s:action_yank(candidate, context) abort
  call setreg('"', a:candidate.word, 'c')
  return 0
endfunction

function! s:open_with_split(direction, candidate, context) abort
  let original_tabpagenr = tabpagenr()
  let original_curwinnr = winnr()
  let original_winrestcmd = winrestcmd()

  let v:errmsg = ''
  silent! execute a:direction 'split'
  if v:errmsg != ''
    return v:errmsg
  endif

  let result = luis#do_action('open', a:candidate, a:context)
  if result isnot 0
    " Undo the last :split.
    close
    execute 'tabnext' original_tabpagenr
    execute original_curwinnr 'wincmd w'
    execute original_winrestcmd
    return result
  endif

  return 0
endfunction

let s:Kind = {
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
