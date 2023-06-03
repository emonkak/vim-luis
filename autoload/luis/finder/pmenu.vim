let s:LNUM_STATUS = 1
let s:LNUM_PATTERN = 2
let s:LNUM_END = 3

let s:PROMPT = '>'

let s:KEYS_TO_START_COMPLETION = "\<C-x>\<C-o>"

let s:BUFFER_NAME = has('win32') || has('win64')
\                 ? '[luis-pmenu-finder]'
\                 : '*luis-pmenu-finder*'

let s:USER_DATA_CAN_ONLY_BE_STRING =
\ has('patch-8.0.1493') && !(has('patch-8.2.0084') || has('nvim-0.5.0'))

let s:SUPPORTS_EQUAL_FIELD_FOR_COMPLETE_ITEMS = has('patch-8.1.1123')

if !exists('s:ui_bufnr')
  let s:ui_bufnr = -1
endif

function! luis#finder#pmenu#define_default_key_mappings() abort
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

function! luis#finder#pmenu#new(...) abort
  let options = get(a:000, 0, {})
  let finder = copy(s:Finder)
  let finder.initial_pattern = get(options, 'initial_pattern', '')
  let finder.is_inserted_by_acc = 0
  let finder.last_candidates = []
  let finder.last_column = -1
  let finder.last_pattern_raw = ''
  let finder.original_backspace = &backspace
  let finder.original_completeopt = &completeopt
  let finder.original_equalalways = &equalalways
  let finder.original_window = 0
  let finder.preview_height = get(options, 'preview_height', &previewheight)
  let finder.preview_width = get(options, 'preview_width', 80)
  let finder.selected_index = -1
  return finder
endfunction

function! luis#finder#pmenu#_omnifunc(findstart, base) abort
  if !exists('b:luis_session')
    return a:findstart ? 0 : []
  endif

  let session = b:luis_session
  let finder = session.finder

  if a:findstart
    let finder.last_candidates = []
    " To determine whether the content of the current pattern is inserted by
    " Vim's completion or not, return 0 to remove the prompt by completion.
    return 0
  else
    let pattern = s:remove_prompt(a:base)
    let candidates = session.collect_candidates(pattern)
    let finder.last_candidates = candidates
    return candidates
  endif
endfunction

let s:Finder = {}

function! s:Finder.guess_candidate() abort dict
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

function! s:Finder.is_active() abort dict
  return bufexists(s:ui_bufnr)
  \      && bufwinnr(s:ui_bufnr) != -1
  \      && getbufvar(s:ui_bufnr, 'luis_session', 0) isnot 0
endfunction

function! s:Finder.normalize_candidate(candidate, index, context) abort
  let a:candidate.equal = 1
  if s:USER_DATA_CAN_ONLY_BE_STRING
    let a:candidate.user_data = json_encode(a:candidate.user_data)
  endif
  return a:candidate
endfunction

function! s:Finder.quit() abort dict
  " Assumption: The current buffer is the luis buffer.
  " We have to check b:luis_sessoin to avoid unnecessary
  " :close'ing, because s:Finder.quit() may be called recursively.
  unlet b:luis_session

  close

  let &backspace = self.original_backspace
  let &equalalways = self.original_equalalways
  let &completeopt = self.original_completeopt

  call win_gotoid(self.original_window)
endfunction

function! s:Finder.refresh_candidates() abort dict
  if self.is_active() && mode() =~# 'i'
    call feedkeys(s:KEYS_TO_START_COMPLETION, 'n')
  endif
endfunction

function! s:Finder.start(session) abort dict
  " Assumption: a:session.finder is self.

  let self.original_window = win_getid()

  " Open or create the finder buffer.
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

  " Remember the session in the buffer for event handlers.
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

function! s:Finder.preview_bounds() abort
  let pum_pos = pum_getpos()
  if !empty(pum_pos)
    let row = float2nr(pum_pos.row + pum_pos.height)
    let col = float2nr(pum_pos.col)
  else
    let row = s:LNUM_END
    let col = 0
  endif
  return {
  \   'row': row,
  \   'col': col,
  \   'width': self.preview_width,
  \   'height': self.preview_height,
  \ }
endfunction

function! s:clone_candidate(candidate) abort
  let candidate = copy(a:candidate)
  if type(candidate.user_data) is v:t_string
    let candidate.user_data = json_decode(a:candidate.user_data)
  endif
  return candidate
endfunction

function! s:complete_prompt() abort
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

function! s:contains_prompt(s) abort
  return len(s:PROMPT) <= len(a:s) && a:s[:len(s:PROMPT) - 1] ==# s:PROMPT
endfunction

function! s:initialize_ui_buffer() abort
  setlocal bufhidden=hide
  setlocal buftype=nofile
  setlocal nobuflisted
  setlocal noswapfile
  setlocal omnifunc=luis#finder#pmenu#_omnifunc
  setlocal undolevels=-1
  silent file `=s:BUFFER_NAME`

  augroup plugin-luis-pmenu
    autocmd!
    autocmd WinLeave <buffer>  call s:on_WinLeave()
    autocmd CursorMovedI <buffer>  call s:on_CursorMovedI()
    autocmd InsertEnter <buffer>  call s:on_InsertEnter()
    if exists('#TextChangedP')
      autocmd TextChangedP <buffer> ++nested  call s:on_TextChangedP()
    endif
  augroup END

  nnoremap <buffer> <expr> <silent> <SID>(choose-action)
         \ exists('b:luis_session')
         \ ? ":<C-u>call b:luis_session.take_action('')<CR>"
         \ : ''
  nnoremap <buffer> <expr> <silent> <SID>(do-default-action)
         \ exists('b:luis_session')
         \ ? ":<C-u>call b:luis_session.take_action('default')<CR>"
         \ : ''
  nnoremap <buffer> <expr> <silent> <SID>(quit-session)
         \ exists('b:luis_session')
         \ ? ':<C-u>call b:luis_session.quit()<CR>'
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

  setfiletype luis-pmenu

  if !exists('#FileType#luis-pmenu') && !exists('b:did_ftplugin')
    call luis#finder#pmenu#define_default_key_mappings()
  endif
endfunction

function! s:keys_to_complete(session) abort
  let finder = a:session.finder
  let cursor_lnum = line('.')
  let cursor_column = col('.')
  let line = getline('.')

  " The order of the following conditions are important.
  if cursor_lnum < s:LNUM_PATTERN
    " Fix the cursor position if it is above the pattern line.
    let keys = repeat("\<Down>", s:LNUM_PATTERN - cursor_lnum)
  elseif !s:contains_prompt(line)
    " Complete the prompt if it doesn't exist for some reasons.
    let keys = repeat("\<Right>", len(s:PROMPT))
    call s:complete_prompt()
  elseif cursor_column <= len(s:PROMPT)
    " Move the cursor out of the prompt if it is in the prompt.
    let keys = repeat("\<Right>", len(s:PROMPT) - cursor_column + 1)
  elseif len(line) < cursor_column && cursor_column != finder.last_column
    let sep = line[-1:]
    " New character is inserted. Let's complete automatically.
    if !finder.is_inserted_by_acc
    \  && finder.selected_index == -1
    \  && len(s:PROMPT) + 2 <= len(line)
    \  && has_key(a:session.source, 'is_special_char')
    \  && a:session.source.is_special_char(sep)
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
      let acc_text = luis#acc_text(
      \   pattern,
      \   finder.last_candidates,
      \   a:session.source,
      \ )
      if acc_text != ''
        " The last special character must be inserted in this way to forcedly
        " show the completion menu.
        call setline('.', acc_text)
        let keys = "\<End>" . sep
        let finder.is_inserted_by_acc = 1
      else
        let keys = s:KEYS_TO_START_COMPLETION
        let finder.is_inserted_by_acc = 0
      endif
    else
      let keys = s:KEYS_TO_START_COMPLETION
      let finder.is_inserted_by_acc = 0
    endif
  else
    let keys = ''
  endif

  let finder.last_column = cursor_column
  let finder.last_pattern_raw = line
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
    if has_key(a:session.source, 'is_special_char')
      for i in range(len(line) - 2, 0, -1)
        if a:session.source.is_special_char(line[i:i])
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

  let finder = b:luis_session.finder
  let finder.is_inserted_by_acc = 0
  let finder.last_column = -1
  let finder.last_pattern_raw = ''

  call feedkeys(s:keys_to_complete(b:luis_session), 'n')
endfunction

function! s:on_TextChangedP() abort
  if !exists('b:luis_session')
    return
  endif

  let session = b:luis_session
  let finder = b:luis_session.finder

  let complete_info = complete_info(['selected'])
  if s:SUPPORTS_EQUAL_FIELD_FOR_COMPLETE_ITEMS && complete_info.selected == -1
    call feedkeys(s:keys_to_complete(session), 'n')
  endif

  " BUGS: complete_info() may return incorrect selected item index. Therefore,
  "       we can only use it to determine whether the selected item exists or
  "       not.
  "       https://github.com/vim/vim/issues/12230
  let finder.selected_index = complete_info.selected

  call session.preview_candidate()
endfunction

function! s:on_WinLeave() abort
  if !exists('b:luis_session')
    return
  endif

  call b:luis_session.quit()
endfunction

function! s:pattern_is_empty() abort
  return getline(s:LNUM_PATTERN) ==# s:PROMPT
endfunction

function! s:remove_prompt(s) abort
  return s:contains_prompt(a:s) ? a:s[len(s:PROMPT):] : a:s
endfunction
