let s:LNUM_STATUS = 1
let s:LNUM_PATTERN = 2

let s:PROMPT = '>'

let s:KEYS_TO_START_COMPLETION = "\<C-x>\<C-o>"

let s:BUFFER_NAME = has('win32') || has('win64')
\                              ? '[luis-menu]'
\                              : '*luis-menu*'

let s:USER_DATA_CAN_ONLY_BE_STRING =
\ has('patch-8.0.1493') && !(has('patch-8.2.0084') || has('nvim-0.5.0'))

if !exists('s:luis_bufnr')
  let s:luis_bufnr = -1
endif

function! luis#ui#menu#define_default_key_mappings() abort
  nmap <buffer> <C-c>  <Plug>(luis-quit-session)
  nmap <buffer> <C-i>  <Plug>(luis-choose-action)
  nmap <buffer> <C-m>  <Plug>(luis-do-default-action)
  nmap <buffer> <CR>  <Plug>(luis-do-default-action)
  nmap <buffer> <Tab>  <Plug>(luis-choose-action)

  imap <buffer> <C-c>  <Plug>(luis-quit-session)
  imap <buffer> <C-i>  <Plug>(luis-choose-action)
  imap <buffer> <C-m>  <Plug>(luis-do-default-action)
  imap <buffer> <CR>  <Plug>(luis-do-default-action)
  imap <buffer> <Tab>  <Plug>(luis-choose-action)

  imap <buffer> <BS>  <Plug>(luis-delete-backward-char)
  imap <buffer> <C-h>  <Plug>(luis-delete-backward-char)
  imap <buffer> <C-u>  <Plug>(luis-delete-backward-line)
  imap <buffer> <C-w>  <Plug>(luis-delete-backward-component)
endfunction

function! luis#ui#menu#new_session(source, ...) abort
  let options = get(a:000, 0, {})
  let session = copy(s:Session)
  let session.initial_pattern = get(options, 'initial_pattern', '')
  let session.is_inserted_by_acc = 0
  let session.is_quitting = 0
  let session.last_candidates = []
  let session.last_column = -1
  let session.last_pattern_raw = ''
  let session.original_backspace = &backspace
  let session.original_completeopt = &completeopt
  let session.original_curwinnr = winnr()
  let session.original_equalalways = &equalalways
  let session.selected_index = -1
  let session.source = a:source
  return session
endfunction

function! luis#ui#menu#_omnifunc(findstart, base) abort
  let session = b:luis_session

  if a:findstart
    let session.last_candidates = []

    " To determine whether the content of the current pattern is inserted by
    " Vim's completion or not, return 0 to remove the prompt by completion.
    return 0
  endif

  let pattern = s:remove_prompt(a:base)
  let source = session.source
  let matcher = has_key(source, 'matcher')
  \           ? source.matcher
  \           : luis#matcher#default#import()
  let context = { 'pattern': pattern, 'matcher': matcher, 'session': session }

  let candidates = source.gather_candidates(context)
  let candidates = matcher.filter_candidates(candidates, context)
  call map(
  \   candidates,
  \   'matcher.normalize_candidate(
  \     s:normalize_candidate(v:val),
  \     v:key,
  \     context
  \   )'
  \ )
  let candidates = matcher.sort_candidates(candidates, context)
  let session.last_candidates = candidates

  return candidates
endfunction

let s:Session = {}

function! s:Session.guess_candidate() abort dict
  if s:is_valid_completed_item(v:completed_item)
    " v:completed_item is a locked dictionary, so it is copied to make it
    " mutable.
    let candidate = copy(v:completed_item)
    if type(candidate.user_data) is v:t_string
      let candidate.user_data = json_decode(candidate.user_data)
    endif
    return candidate
  endif

  " The fallback for when v:completed_item is not available.
  let current_pattern_raw = getline(s:LNUM_PATTERN)
  if current_pattern_raw !=# self.last_pattern_raw
    " current_pattern_raw seems to be inserted by Vim's completion,
    " so user seemed to select a candidate by Vim's completion.
    for candidate in self.last_candidates
      if current_pattern_raw ==# candidate.word
        return candidate
      endif
    endfor

    let errmsg = 'luis: No match found in self.last_candidates:' . "\n"
    \          . '  current_pattern_raw: ' . string(current_pattern_raw) . "\n"
    \          . '  last_pattern_raw: ' . string(self.last_pattern_raw) . "\n"
    \          . '  last_candidates: ' . string(self.last_candidates)
    echoerr errmsg
    return 0
  endif

  if len(self.last_candidates) > 0
    " There are 1 or more candidates -- user seems to want to take action on
    " the first one.
    return self.last_candidates[0]
  endif

  " There is no candidate -- user seems to want to take action on
  " current_pattern_raw with fake sources.
  return {
  \   'word': s:remove_prompt(current_pattern_raw),
  \   'user_data': {},
  \ }
endfunction

function! s:Session.is_active() abort dict
  return bufexists(s:luis_bufnr) && bufwinnr(s:luis_bufnr) != -1
endfunction

function! s:Session.quit() abort dict
  " Assumption: The current buffer is the luis buffer.
  " We have to check self.is_quitting to avoid unnecessary
  " :close'ing, because s:Session.quit() may be called recursively.
  let self.is_quitting = 1

  close

  let &backspace = self.original_backspace
  let &equalalways = self.original_equalalways
  let &completeopt = self.original_completeopt
  execute self.original_curwinnr 'wincmd w'

  let self.is_quitting = 0
endfunction

function! s:Session.start() abort dict
  " Open or create the luis buffer.
  if bufexists(s:luis_bufnr)
    topleft split
    silent execute s:luis_bufnr 'buffer'
  else
    topleft new
    let s:luis_bufnr = bufnr('')
    call s:initialize_luis_buffer()
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

function! s:Session.reload_candidates() abort dict
  if self.is_active() && mode() =~# 'i'
    call feedkeys(s:KEYS_TO_START_COMPLETION, 'n')
  endif
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

function! s:initialize_luis_buffer() abort
  setlocal bufhidden=hide
  setlocal buftype=nofile
  setlocal nobuflisted
  setlocal noswapfile
  setlocal omnifunc=luis#ui#menu#_omnifunc
  silent file `=s:BUFFER_NAME`

  augroup plugin-luis
    autocmd BufLeave,WinLeave <buffer>
    \   if !b:luis_session.is_quitting
    \ |   call luis#quit()
    \ | endif
    autocmd BufUnload <buffer>  let s:luis_bufnr = -1
    autocmd CursorMovedI <buffer>  call s:on_CursorMovedI()
    autocmd InsertEnter <buffer>  call s:on_InsertEnter()
    if has('patch-8.1.1123')  " Has 'equal' field support for complete items.
      autocmd TextChangedP <buffer>  call s:on_TextChangedP()
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

  setfiletype luis-menu

  if !exists('#FileType#luis-menu') && !exists('b:did_ftplugin')
    call luis#ui#menu#define_default_key_mappings()
  endif
endfunction

function! s:is_valid_completed_item(completed_item) abort
  return has_key(a:completed_item, 'user_data')
  \      && a:completed_item.user_data isnot ''
endfunction

function! s:keys_to_complete() abort
  let session = b:luis_session
  let cursor_column = col('.')
  let line = getline('.')

  " The order of the following conditions are important.
  if !s:contains_the_prompt(line)
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
      let acc_text = luis#_acc_text(
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

function! s:normalize_candidate(candidate) abort
  let a:candidate.equal = 1
  if !has_key(a:candidate, 'user_data')
    let a:candidate.user_data = {}
  endif
  if s:USER_DATA_CAN_ONLY_BE_STRING
    let a:candidate.user_data = json_encode(a:candidate.user_data)
  endif
  if !has_key(a:candidate, 'luis_sort_priority')
    let a:candidate.luis_sort_priority = 0
  endif
  return a:candidate
endfunction

function! s:on_CursorMovedI() abort
  call feedkeys(s:keys_to_complete(), 'n')
endfunction

function! s:on_InsertEnter() abort
  let session = b:luis_session
  let session.is_inserted_by_acc = 0
  let session.last_column = -1
  let session.last_pattern_raw = ''
  call feedkeys(s:keys_to_complete(), 'n')
endfunction

function! s:on_TextChangedP() abort
  " BUGS: complete_info() may return incorrect selected item index. Therefore,
  "       we can only use it to determine whether the selected item exists or
  "       not.
  "       https://github.com/vim/vim/issues/12230
  let complete_info = complete_info(['selected'])
  if complete_info.selected == -1
    call feedkeys(s:keys_to_complete(), 'n')
  endif

  let session = b:luis_session
  let session.selected_index = complete_info.selected

  if has_key(session.source, 'on_preview')
    let candidate = session.guess_candidate()
    if candidate isnot 0
      let context = { 'session': session }
      call session.source.on_preview(candidate, context)
    endif
  endif
endfunction

function! s:remove_prompt(s) abort
  return s:contains_the_prompt(a:s) ? a:s[len(s:PROMPT):] : a:s
endfunction
