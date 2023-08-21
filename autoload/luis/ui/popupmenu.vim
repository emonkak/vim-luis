let s:LNUM_STATUS = 1
let s:LNUM_PATTERN = 2

let s:PROMPT = '>'

let s:KEYS_TO_START_COMPLETION = "\<C-x>\<C-o>"

let s:USER_DATA_CAN_ONLY_BE_STRING =
\ has('patch-8.0.1493') && !(has('patch-8.2.0084') || has('nvim-0.5.0'))

let s:SUPPORTS_EQUAL_FIELD_FOR_COMPLETE_ITEMS = has('patch-8.1.1123')

function! luis#ui#popupmenu#define_default_key_mappings() abort
  nmap <buffer> <C-c>  <Plug>(luis-quit-session)
  nmap <buffer> <C-i>  <Plug>(luis-choose-action)
  nmap <buffer> <C-m>  <Plug>(luis-do-default-action)
  nmap <buffer> <CR>  <Plug>(luis-do-default-action)
  nmap <buffer> <Esc>  <Plug>(luis-quit-session)
  nmap <buffer> <Tab>  <Plug>(luis-choose-action)

  imap <buffer> <C-c>  <Plug>(luis-quit-session)
  imap <buffer> <C-i>  <Plug>(luis-choose-action)
  imap <buffer> <C-m>  <Plug>(luis-do-default-action)
  imap <buffer> <CR>  <Plug>(luis-do-default-action)
  imap <buffer> <Esc>  <Plug>(luis-quit-session)
  imap <buffer> <Tab>  <Plug>(luis-choose-action)

  imap <buffer> <expr> <BS>  <SID>pattern_is_empty()
                           \ ? '<Plug>(luis-quit-session)'
                           \ : '<Plug>(luis-delete-backward-char)'
  imap <buffer> <expr> <C-h>  <SID>pattern_is_empty()
                            \ ? '<Plug>(luis-quit-session)'
                            \ : '<Plug>(luis-delete-backward-char)'
  imap <buffer> <expr> <C-u>  <SID>pattern_is_empty()
                            \ ? '<Plug>(luis-quit-session)'
                            \ : '<Plug>(luis-delete-backward-line)'
  imap <buffer> <expr> <C-w>  <SID>pattern_is_empty()
                            \ ? '<Plug>(luis-quit-session)'
                            \ : '<Plug>(luis-delete-backward-component)'
endfunction

function! luis#ui#popupmenu#new(...) abort
  let options = get(a:000, 0, {})
  let ui = copy(s:UI)
  let ui.buffer_name = has_key(options, 'buffer_name')
  \                  ? options.buffer_name
  \                  : has('win32') || has('win64')
  \                  ? '[luis-popupmenu-ui]'
  \                  : '*luis-popupmenu-ui*'
  let ui.bufnr = -1
  let ui.is_inserted_by_acc = 0
  let ui.last_candidates = []
  let ui.last_column = -1
  let ui.last_pattern_raw = ''
  let ui.last_session_id = -1
  let ui.original_backspace = &backspace
  let ui.original_completeopt = &completeopt
  let ui.original_equalalways = &equalalways
  let ui.original_window = 0
  let ui.preview_height = get(options, 'preview_height', &previewheight)
  let ui.preview_width = get(options, 'preview_width', 80)
  return ui
endfunction

function! luis#ui#popupmenu#_omnifunc(findstart, base) abort
  if !exists('b:luis_session')
    return a:findstart ? 0 : []
  endif

  if a:findstart
    let ui = b:luis_session.ui
    let ui.last_candidates = []
    " To determine whether the content of the current pattern is inserted by
    " Vim's completion or not, return 0 to remove the prompt by completion.
    return 0
  else
    let pattern = s:remove_prompt(a:base)
    let candidates = luis#collect_candidates(b:luis_session, pattern)
    let ui = b:luis_session.ui
    let ui.last_candidates = candidates
    return candidates
  endif
endfunction

let s:UI = {}

function! s:UI.current_pattern() abort dict
  let current_pattern_raw = getline(s:LNUM_PATTERN)
  return s:remove_prompt(current_pattern_raw)
endfunction

function! s:UI.guess_candidate() abort dict
  if get(v:completed_item, 'user_data', '') isnot ''
    return s:clone_candidate(v:completed_item)
  endif

  let current_pattern_raw = getline(s:LNUM_PATTERN)
  if current_pattern_raw !=# self.last_pattern_raw
    " current_pattern_raw seems to be inserted by Vim's completion,
    " so user seemed to select a candidate by Vim's completion.
    for candidate in self.last_candidates
      if current_pattern_raw ==# candidate.word
        return s:clone_candidate(candidate)
      endif
    endfor
  else
    if len(self.last_candidates) > 0
      " There are 1 or more candidates -- user seems to want to take action on
      " the first one.
      return s:clone_candidate(self.last_candidates[0])
    endif
  endif

  " There is no candidate.
  return 0
endfunction

function! s:UI.is_active() abort dict
  return bufexists(self.bufnr)
  \      && bufwinnr(self.bufnr) != -1
  \      && getbufvar(self.bufnr, 'luis_session', 0) isnot 0
endfunction

function! s:UI.normalize_candidate(candidate, index, context) abort
  let a:candidate.equal = 1
  if s:USER_DATA_CAN_ONLY_BE_STRING
    let a:candidate.user_data = json_encode(a:candidate.user_data)
  endif
  return a:candidate
endfunction

function! s:UI.preview_bounds() abort
  let row = screenrow()
  if pumvisible()
    if &pumheight > 0
      let row += min([len(self.last_candidates), &pumheight])
    else
      let row += min([len(self.last_candidates), &rows - row])
    endif
  endif
  return {
  \   'row': row,
  \   'col': 0,
  \   'width': self.preview_width,
  \   'height': self.preview_height,
  \ }
endfunction

function! s:UI.quit() abort dict
  " Assumption: The current buffer is the UI buffer.
  " We have to check b:luis_sessoin to avoid unnecessary
  " :close'ing, because s:UI.quit() may be called recursively.
  unlet b:luis_session

  close

  let &backspace = self.original_backspace
  let &equalalways = self.original_equalalways
  let &completeopt = self.original_completeopt

  call win_gotoid(self.original_window)
endfunction

function! s:UI.refresh_candidates() abort dict
  if self.is_active() && mode() =~# 'i'
    call feedkeys(s:KEYS_TO_START_COMPLETION, 'n')
  endif
endfunction

function! s:UI.start(session) abort dict
  if a:session.ui isnot self
    echoerr 'a:session.ui must be same as self, but got:' string(session.ui)
    return
  endif

  let self.original_window = win_getid()

  " Open or create the ui buffer.
  if bufexists(self.bufnr)
    let is_loaded = bufloaded(self.bufnr)
    topleft split
    silent execute self.bufnr 'buffer'
    if !is_loaded
      call s:initialize_ui_buffer(self.buffer_name)
    endif
  else
    topleft new
    let self.bufnr = bufnr('%')
    call s:initialize_ui_buffer(self.buffer_name)
  endif
  2 wincmd _

  " Remember the session in this buffer for event handlers.
  let b:luis_session = a:session

  " Set some options.
  " Ensure to allow backspacing after ACC, etc. These features move the cursor
  " in Insert mode and such operation starts new Insert mode, so that
  " backspacing may not work after ACC, etc if the value of 'backspace' is
  " not properly set.
  set backspace=eol,indent,start
  " Ensure to show ins-completion-menu while automatic completion.
  set completeopt=menu,menuone,noselect
  set noequalalways

  " Reset the content of the UI buffer.
  " BUGS: To avoid unexpected behavior caused by automatic completion of the
  "       prompt, append the prompt and {initial-pattern} at this timing.
  "       Automatic completion is implemented by feedkeys() and starting
  "       Insert mode is also implemented by feedkeys(). These feedings must
  "       be done carefully.
  silent % delete _
  if a:session.id == self.last_session_id
    " Restore the previous pattern when starting the same session as last time.
    let pattern = self.last_pattern_raw != ''
    \           ? self.last_pattern_raw
    \           : s:PROMPT
  else
    let pattern = s:PROMPT . a:session.initial_pattern
    let self.last_session_id = a:session.id
  endif
  call setline(s:LNUM_STATUS, 'Source: ' . a:session.source.name)
  call setline(s:LNUM_PATTERN, pattern)
  execute 'normal!' s:LNUM_PATTERN . 'G'

  " Start Insert mode.
  " BUGS: :startinsert! may not work with append()/setline()/:put.
  "       If the typeahead buffer is empty, there is no problem.
  "       Otherwise, :startinsert! behaves as '$i', not 'A',
  "       so it is inconvenient.
  " BUGS: It's not possible to emulate the same input by
  "       s:consume_typeahead_buffer() and feedkeys(). Because there is no
  "       way to get information on the source of an input character, for
  "       example, typed character, mapped character, etc.
  let typeahead_buffer = s:consume_typeahead_buffer()
  call feedkeys('A' . typeahead_buffer, 'n')
endfunction

function! s:clone_candidate(candidate) abort
  let candidate = copy(a:candidate)
  if type(candidate.user_data) is v:t_string
    let candidate.user_data = json_decode(a:candidate.user_data)
  else
    let candidate.user_data = copy(candidate.user_data)
  endif
  return candidate
endfunction

function! s:consume_typeahead_buffer() abort
  let buffer = ''

  while 1
    let c = getchar(0)
    if c is 0
      break
    endif
    let buffer .= type(c) is v:t_number ? nr2char(c) : c
  endwhile

  return buffer
endfunction

function! s:contains_prompt(s) abort
  return len(s:PROMPT) <= len(a:s) && a:s[:len(s:PROMPT) - 1] ==# s:PROMPT
endfunction

function! s:initialize_ui_buffer(buffer_name) abort
  setlocal bufhidden=hide
  setlocal buftype=nofile
  setlocal nobuflisted
  setlocal noswapfile
  setlocal omnifunc=luis#ui#popupmenu#_omnifunc
  setlocal undolevels=-1
  silent file `=a:buffer_name`

  augroup plugin-luis-popupmenu-ui
    autocmd!
    autocmd CursorMovedI <buffer>  call s:on_CursorMovedI()
    autocmd InsertEnter <buffer>  call s:on_InsertEnter()
    if exists('##TextChangedP')
      " Enable the ++nested option to allow executing autocmd on the buffer
      " during preview.
      autocmd TextChangedP <buffer> ++nested  call s:on_TextChangedP()
    endif
    autocmd WinLeave <buffer>  call s:on_WinLeave()
  augroup END

  nnoremap <buffer> <expr> <silent> <SID>(choose-action)
         \ exists('b:luis_session')
         \ ? ":<C-u>call luis#take_action(b:luis_session, '*')<CR>"
         \ : ''
  nnoremap <buffer> <expr> <silent> <SID>(do-default-action)
         \ exists('b:luis_session')
         \ ? ":<C-u>call luis#take_action(b:luis_session, 'default')<CR>"
         \ : ''
  nnoremap <buffer> <expr> <silent> <SID>(quit-session)
         \ exists('b:luis_session')
         \ ? ':<C-u>call luis#quit(b:luis_session)<CR>'
         \ : ''
  inoremap <buffer> <expr> <SID>(accept-completion)
  \        pumvisible() ? '<C-y>' : ''
  inoremap <buffer> <expr> <SID>(cancel-completion)
  \        pumvisible() ? '<C-e>' : ''
  inoremap <buffer> <expr> <SID>(delete-backward-char)
  \        pumvisible() ? '<C-y><BS>' : '<BS>'
  inoremap <buffer> <expr> <SID>(delete-backward-line)
  \        pumvisible() ? '<C-e><C-u>' : '<C-u>'
  inoremap <buffer> <expr> <SID>(delete-backward-component)
         \ exists('b:luis_session')
         \ ? <SID>keys_to_delete_backward_component(b:luis_session)
         \ : ''

  nnoremap <buffer> <script> <Plug>(luis-choose-action)
  \        <SID>(choose-action)
  nnoremap <buffer> <script> <Plug>(luis-do-default-action)
  \        <SID>(do-default-action)
  nnoremap <buffer> <script> <Plug>(luis-quit-session)
  \        <SID>(quit-session)

  inoremap <buffer> <script> <Plug>(luis-choose-action)
  \        <SID>(accept-completion)<Esc><SID>(choose-action)
  inoremap <buffer> <script> <Plug>(luis-do-default-action)
  \        <SID>(accept-completion)<Esc><SID>(do-default-action)
  inoremap <buffer> <script> <Plug>(luis-quit-session)
  \        <Esc><SID>(quit-session)

  inoremap <buffer> <script> <Plug>(luis-delete-backward-char)
  \        <SID>(delete-backward-char)
  inoremap <buffer> <script> <Plug>(luis-delete-backward-line)
  \        <SID>(delete-backward-line)
  inoremap <buffer> <script> <Plug>(luis-delete-backward-component)
  \        <SID>(delete-backward-component)

  setfiletype luis-popupmenu-ui

  if !exists('#FileType#luis-popupmenu-ui') && !exists('b:did_ftplugin')
    call luis#ui#popupmenu#define_default_key_mappings()
  endif
endfunction

function! s:keys_to_complete(session) abort
  let ui = a:session.ui
  let lnum = line('.')
  let column = col('.')
  let line = getline(lnum)

  " The order of the following conditions are important.
  if lnum < s:LNUM_PATTERN
    " Fix the cursor position if it is above the pattern line.
    let keys = repeat("\<Down>", s:LNUM_PATTERN - lnum)
  elseif lnum > s:LNUM_PATTERN
    " Delete all lines until the pattern line.
    let keys = repeat("\<Up>", (lnum - s:LNUM_PATTERN - 1)) . "\<C-o>dG"
  elseif len(line) < column && column != ui.last_column
    " A new character is inserted. Let's complete automatically.
    let sep = line[-1:]
    if !ui.is_inserted_by_acc
    \  && s:contains_prompt(line)
    \  && len(s:PROMPT) + 2 <= len(line)
    \  && has_key(a:session.source, 'is_component_separator')
    \  && a:session.source.is_component_separator(sep)
      " (1) The last inserted character is not inserted by ACC.
      " (2) It seems not to be inserted by Vim's completion.
      " (3) It seems not to be the 1st one in the line.
      " (4) It is a component separator for the current source.
      "
      " The (3) is necessary to input a special character as the 1st character
      " in line. For example, without this condition, user cannot input the
      " 1st '/' of an absolute path like '/usr/local/bin' if '/' is a special
      " character.
      let pattern = s:remove_prompt(line)
      let acc_text = luis#acc_text(
      \   pattern,
      \   ui.last_candidates,
      \   a:session.source,
      \ )
      if acc_text != ''
        " The last special character must be inserted in this way to forcedly
        " show the completion menu.
        call setline(lnum, s:PROMPT . acc_text . sep)
        let keys = "\<End>" . s:KEYS_TO_START_COMPLETION
        let ui.is_inserted_by_acc = 1
      else
        let keys = s:KEYS_TO_START_COMPLETION
        let ui.is_inserted_by_acc = 0
      endif
    else
      let keys = s:KEYS_TO_START_COMPLETION
      let ui.is_inserted_by_acc = 0
    endif
  elseif !s:contains_prompt(line)
    " Complete the prompt if it doesn't exist for some reasons.
    let keys = repeat("\<Right>", len(s:PROMPT))
    call setline(lnum, s:PROMPT . line)
  elseif column <= len(s:PROMPT)
    " Move the cursor out of the prompt if it is in the prompt.
    let keys = repeat("\<Right>", len(s:PROMPT) - column + 1)
  else
    let keys = ''
  endif

  let ui.last_column = column
  let ui.last_pattern_raw = line
  return keys
endfunction

function! s:keys_to_delete_backward_component(session) abort
  " In the following figures,
  " '|' means the cursor position, and
  " '^' means characters to delete:
  "
  "   >/usr/local/b|
  "               ^
  "
  "   >/usr/local/|
  "         ^^^^^^
  "
  "   >/usr/|
  "     ^^^^
  let line = getline('.')
  if len(line) < col('.')
    if has_key(a:session.source, 'is_component_separator')
      for i in range(len(line) - 2, 0, -1)
        if a:session.source.is_component_separator(line[i:i])
          let num_chars = strchars(line[i + 1:])
          return (pumvisible() ? "\<C-y>" : '') . repeat("\<BS>", num_chars)
        endif
      endfor
    endif
    " No component separator - delete everything.
    return (pumvisible() ? "\<C-e>" : '') . "\<C-u>"
  else
    " Don't consider cases that the cursor doesn't point the end of the
    " current line.
    return (pumvisible() ? "\<C-e>" : '') . "\<C-w>"
  endif
endfunction

function! s:on_CursorMovedI() abort
  if !exists('b:luis_session')
    return
  endif

  call feedkeys(s:keys_to_complete(b:luis_session), 'n')
endfunction

function! s:on_InsertEnter() abort
  if !exists('b:luis_session')
    return
  endif

  let ui = b:luis_session.ui
  let ui.is_inserted_by_acc = 0
  let ui.last_candidates = []
  let ui.last_column = -1
  let ui.last_pattern_raw = ''

  call feedkeys(s:keys_to_complete(b:luis_session), 'n')
endfunction

function! s:on_TextChangedP() abort
  if !exists('b:luis_session')
    return
  endif

  let complete_info = complete_info(['selected'])
  if s:SUPPORTS_EQUAL_FIELD_FOR_COMPLETE_ITEMS && complete_info.selected == -1
    call feedkeys(s:keys_to_complete(b:luis_session), 'n')
  endif

  call luis#preview_candidate(b:luis_session)
endfunction

function! s:on_WinLeave() abort
  if !exists('b:luis_session')
    return
  endif

  call luis#quit(b:luis_session)
endfunction

function! s:pattern_is_empty() abort
  return getline(s:LNUM_PATTERN) ==# s:PROMPT
endfunction

function! s:remove_prompt(s) abort
  return s:contains_prompt(a:s) ? a:s[len(s:PROMPT):] : a:s
endfunction
