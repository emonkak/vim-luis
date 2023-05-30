let s:LNUM_STATUS = 1
let s:LNUM_PATTERN = 2
let s:LNUM_END = 3

let s:PROMPT = '>'

let s:KEYS_TO_START_COMPLETION = "\<C-x>\<C-o>"

let s:UI_BUFFER_NAME = has('win32') || has('win64')
\                    ? '[luis-pmenu]'
\                    : '*luis-pmenu*'

let s:USER_DATA_CAN_ONLY_BE_STRING =
\ has('patch-8.0.1493') && !(has('patch-8.2.0084') || has('nvim-0.5.0'))

let s:SUPPORTS_EQUAL_FIELD_FOR_COMPLETE_ITEMS = has('patch-8.1.1123')

if !exists('s:ui_bufnr')
  let s:ui_bufnr = -1
endif

function! luis#ui#pmenu#define_default_key_mappings() abort
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

function! luis#ui#pmenu#new_session(source, ...) abort
  let options = get(a:000, 0, {})
  let session = copy(s:Session)
  let session.hook = get(options, 'hook', {})
  let session.initial_pattern = get(options, 'initial_pattern', '')
  let session.is_inserted_by_acc = 0
  let session.is_quitting = 0
  let session.last_candidates = []
  let session.last_column = -1
  let session.last_pattern_raw = ''
  let session.original_backspace = &backspace
  let session.original_completeopt = &completeopt
  let session.original_equalalways = &equalalways
  let session.original_window = 0
  let session.preview = get(options, 'preview', 0)
  let session.preview_height = get(options, 'preview_height', &previewheight)
  let session.preview_width = get(options, 'preview_width', 80)
  let session.selected_index = -1
  let session.source = a:source
  return session
endfunction

function! luis#ui#pmenu#_omnifunc(findstart, base) abort
  let session = b:luis_session

  if a:findstart
    let session.last_candidates = []
    " To determine whether the content of the current pattern is inserted by
    " Vim's completion or not, return 0 to remove the prompt by completion.
    return 0
  else
    let pattern = s:remove_prompt(a:base)
    let candidates = luis#ui#collect_candidates(
    \   session,
    \   pattern
    \ )
    let session.last_candidates = candidates
    return candidates
  endif
endfunction

let s:Session = {}

function! s:Session.guess_candidate() abort dict
  if has_key(v:completed_item, 'user_data')
  \  && v:completed_item.user_data isnot ''
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

  " There is no candidate -- user seems to want to take action on
  " current_pattern_raw with fake sources.
  return {
  \   'word': s:remove_prompt(current_pattern_raw),
  \   'user_data': {},
  \ }
endfunction

function! s:Session.is_active() abort dict
  return bufexists(s:ui_bufnr)
  \      && bufwinnr(s:ui_bufnr) != -1
  \      && getbufvar(s:ui_bufnr, 'luis_session', 0) is self
endfunction

function! s:Session.normalize_candidate(candidate, index, context) abort
  let a:candidate.equal = 1
  if !has_key(a:candidate, 'user_data')
    let a:candidate.user_data = {}
  endif
  if s:USER_DATA_CAN_ONLY_BE_STRING
    let a:candidate.user_data = json_encode(a:candidate.user_data)
  endif
  return a:candidate
endfunction

function! s:Session.quit() abort dict
  " Assumption: The current buffer is the luis buffer.
  " We have to check self.is_quitting to avoid unnecessary
  " :close'ing, because s:Session.quit() may be called recursively.
  let self.is_quitting = 1

  try
    if luis#preview#is_enabled()
      call luis#preview#quit()
    endif

    unlet b:luis_session

    close

    let &backspace = self.original_backspace
    let &equalalways = self.original_equalalways
    let &completeopt = self.original_completeopt

    call win_gotoid(self.original_window)
  finally
    let self.is_quitting = 0
  endtry
endfunction

function! s:Session.reload_candidates() abort dict
  if self.is_active() && mode() =~# 'i'
    call feedkeys(s:KEYS_TO_START_COMPLETION, 'n')
  endif
endfunction

function! s:Session.start() abort dict
  let self.original_window = win_getid()

  " Open or create the UI buffer.
  if bufexists(s:ui_bufnr)
    let is_loaded = bufloaded(s:ui_bufnr)
    topleft split
    silent execute s:ui_bufnr 'buffer'
    if !is_loaded
      call s:initialize_ui_buffer()
    endif
  else
    topleft new
    let s:ui_bufnr = bufnr('%')
    call s:initialize_ui_buffer()
  endif
  2 wincmd _

  " Remember the luis session in the buffer for event handlers.
  let b:luis_session = self

  " Set some options.
  " Ensure to allow backspacing after ACC, etc. These features move the cursor
  " in Insert mode and such operation starts new Insert mode, so that
  " backspacing may not work after ACC, etc if the value of 'backspace' is
  " not properly set.
  set backspace=eol,indent,start
  " Ensure to show ins-completion-menu while automatic completion.
  set completeopt=menu,menuone,noselect
  set noequalalways

  " Reset the content of the luis buffer.
  " BUGS: To avoid unexpected behavior caused by automatic completion of the
  "       prompt, append the prompt and {initial-pattern} at this timing.
  "       Automatic completion is implemented by feedkeys() and starting
  "       Insert mode is also implemented by feedkeys(). These feedings must
  "       be done carefully.
  silent % delete _
  let pattern = self.last_pattern_raw != ''
  \           ? self.last_pattern_raw
  \           : s:PROMPT . self.initial_pattern
  call setline(s:LNUM_STATUS, 'Source: ' . self.source.name)
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
  endif
  return candidate
endfunction

function! s:complete_the_prompt() abort
  call setline('.', s:PROMPT . getline('.'))
  return
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

function! s:contains_the_prompt(s) abort
  return len(s:PROMPT) <= len(a:s) && a:s[:len(s:PROMPT) - 1] ==# s:PROMPT
endfunction

function! s:initialize_ui_buffer() abort
  setlocal bufhidden=hide
  setlocal buftype=nofile
  setlocal nobuflisted
  setlocal noswapfile
  setlocal omnifunc=luis#ui#pmenu#_omnifunc
  setlocal undolevels=-1
  silent file `=s:UI_BUFFER_NAME`

  augroup plugin-luis-pmenu
    autocmd!
    autocmd WinLeave <buffer>  call s:on_WinLeave()
    autocmd CursorMovedI <buffer>  call s:on_CursorMovedI()
    autocmd InsertEnter <buffer>  call s:on_InsertEnter()
    if exists('#TextChangedP')
      autocmd TextChangedP <buffer> ++nested  call s:on_TextChangedP()
    endif
  augroup END

  nnoremap <buffer> <silent> <SID>(choose-action)
  \        :<C-u>call luis#take_action()<CR>
  nnoremap <buffer> <silent> <SID>(do-default-action)
  \        :<C-u>call luis#take_action('default')<CR>
  nnoremap <buffer> <silent> <SID>(quit-session)
  \        :<C-u>call luis#quit()<CR>
  inoremap <buffer> <expr> <SID>(accept-completion)
  \        pumvisible() ? '<C-y>' : ''
  inoremap <buffer> <expr> <SID>(cancel-completion)
  \        pumvisible() ? '<C-e>' : ''
  inoremap <buffer> <expr> <SID>(delete-backward-char)
  \        pumvisible() ? '<C-y><BS>' : '<BS>'
  inoremap <buffer> <expr> <SID>(delete-backward-line)
  \        pumvisible() ? '<C-e><C-u>' : '<C-u>'
  inoremap <buffer> <expr> <SID>(delete-backward-component)
  \        <SID>keys_to_delete_backward_component()

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

  setfiletype luis-pmenu

  if !exists('#FileType#luis-pmenu') && !exists('b:did_ftplugin')
    call luis#ui#pmenu#define_default_key_mappings()
  endif
endfunction

function! s:keys_to_complete() abort
  let session = b:luis_session
  let cursor_lnum = line('.')
  let cursor_column = col('.')
  let line = getline('.')

  " The order of the following conditions are important.
  if cursor_lnum < s:LNUM_PATTERN
    " Fix the cursor position if it is above the pattern line.
    let keys = repeat("\<Down>", s:LNUM_PATTERN - cursor_lnum)
  elseif !s:contains_the_prompt(line)
    " Complete the prompt if it doesn't exist for some reasons.
    let keys = repeat("\<Right>", len(s:PROMPT))
    call s:complete_the_prompt()
  elseif cursor_column <= len(s:PROMPT)
    " Move the cursor out of the prompt if it is in the prompt.
    let keys = repeat("\<Right>", len(s:PROMPT) - cursor_column + 1)
  elseif len(line) < cursor_column && cursor_column != session.last_column
    let sep = line[-1:]
    " New character is inserted. Let's complete automatically.
    if !session.is_inserted_by_acc
    \  && session.selected_index == -1
    \  && len(s:PROMPT) + 2 <= len(line)
    \  && has_key(session.source, 'is_special_char')
    \  && session.source.is_special_char(sep)
      " (1) The last inserted character is not inserted by ACC.
      " (2) The selected item does not exist.
      " (3) It seems not to be the 1st one in line.
      " (4) It is a special character for current source
      "
      " The (4) is necessary to input a special character as the 1st character
      " in line. For example, without this condition, user cannot input the
      " 1st '/' of an absolute path like '/usr/local/bin' if '/' is a special
      " character.
      let pattern = s:remove_prompt(line)
      let acc_text = luis#ui#acc_text(
      \   pattern,
      \   session.last_candidates,
      \   session.source
      \ )
      if acc_text != ''
        " The last special character must be inserted in this way to forcedly
        " show the completion menu.
        call setline('.', acc_text)
        let keys = "\<End>" . sep
        let session.is_inserted_by_acc = 1
      else
        let keys = s:KEYS_TO_START_COMPLETION
        let session.is_inserted_by_acc = 0
      endif
    else
      let keys = s:KEYS_TO_START_COMPLETION
      let session.is_inserted_by_acc = 0
    endif
  else
    let keys = ''
  endif

  let session.last_column = cursor_column
  let session.last_pattern_raw = line
  return keys
endfunction

function! s:keys_to_delete_backward_component() abort
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
  let session = b:luis_session
  let line = getline('.')
  if len(line) < col('.')
    if has_key(session.source, 'is_special_char')
      for i in range(len(line) - 2, 0, -1)
        if session.source.is_special_char(line[i:i])
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

  call feedkeys(s:keys_to_complete(), 'n')
endfunction

function! s:on_InsertEnter() abort
  if !exists('b:luis_session')
    return
  endif

  let session = b:luis_session
  let session.is_inserted_by_acc = 0
  let session.last_column = -1
  let session.last_pattern_raw = ''
  call feedkeys(s:keys_to_complete(), 'n')
endfunction

function! s:on_TextChangedP() abort
  if !exists('b:luis_session')
    return
  endif

  " BUGS: complete_info() may return incorrect selected item index. Therefore,
  "       we can only use it to determine whether the selected item exists or
  "       not.
  "       https://github.com/vim/vim/issues/12230
  let complete_info = complete_info(['selected'])
  if s:SUPPORTS_EQUAL_FIELD_FOR_COMPLETE_ITEMS && complete_info.selected == -1
    call feedkeys(s:keys_to_complete(), 'n')
  endif

  let session = b:luis_session
  let session.selected_index = complete_info.selected

  if luis#preview#is_enabled()
    let [row, col] = s:preview_pos()
    let dimensions = {
    \   'row': row,
    \   'col': col,
    \   'width': session.preview_width,
    \   'height': session.preview_height,
    \ }
    call luis#preview#start(session, dimensions)
  endif
endfunction

function! s:on_WinLeave() abort
  if !exists('b:luis_session')
    return
  endif

  call luis#quit()
endfunction

function! s:pattern_is_empty() abort
  return getline(s:LNUM_PATTERN) ==# s:PROMPT
endfunction

function! s:preview_pos() abort
  let pum_pos = pum_getpos()
  if !empty(pum_pos)
    let row = float2nr(pum_pos.row + pum_pos.height)
    let col = float2nr(pum_pos.col)
  else
    let row = s:LNUM_END
    let col = 0
  endif
  return [row, col]
endfunction

function! s:remove_prompt(s) abort
  return s:contains_the_prompt(a:s) ? a:s[len(s:PROMPT):] : a:s
endfunction
