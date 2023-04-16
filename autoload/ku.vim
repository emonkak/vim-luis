" ku - Interface for everything
" Version: 0.3.0
" Copyright (C) 2008-2009 kana <http://whileimautomaton.net/>
" License: MIT license  {{{
"     Permission is hereby granted, free of charge, to any person obtaining
"     a copy of this software and associated documentation files (the
"     "Software"), to deal in the Software without restriction, including
"     without limitation the rights to use, copy, modify, merge, publish,
"     distribute, sublicense, and/or sell copies of the Software, and to
"     permit persons to whom the Software is furnished to do so, subject to
"     the following conditions:
"
"     The above copyright notice and this permission notice shall be included
"     in all copies or substantial portions of the Software.
"
"     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
"     OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
"     MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
"     IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
"     CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
"     TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
"     SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
" }}}
" Constants  "{{{1

let s:FALSE = 0
let s:TRUE = !s:FALSE

let s:LNUM_STATUS = 1
let s:LNUM_PATTERN = 2

if has('win16') || has('win32') || has('win64')  " on Microsoft Windows
  let s:KU_BUFFER_NAME = '[ku]'
else
  let s:KU_BUFFER_NAME = '*ku*'
endif

let s:PROMPT = '>'

let s:KEYS_TO_START_COMPLETION = "\<C-x>\<C-o>\<C-p>"

let s:SCHEMA_KIND = {
\   'type': 'struct',
\   'properties': {
\     'action_table': {
\       'type': 'dictionary',
\       'item': {
\         'type': v:t_func,
\       },
\     },
\     'key_table': {
\       'type': 'dictionary',
\       'item': {
\         'type': v:t_string,
\       },
\     },
\   },
\ }

let s:SCHEMA_KIND.properties.prototype = {
\   'type': 'struct',
\   'properties': s:SCHEMA_KIND.properties,
\   'optional': 1,
\ }

let s:SCHEMA_MATCHER = {
\   'type': 'struct',
\   'properties': {
\      'match_candidates': {
\        'type': v:t_func,
\      },
\    },
\ }

let s:SCHEMA_SOURCE = {
\   'type': 'struct',
\   'properties': {
\     'name': {
\       'type': v:t_string,
\     },
\     'default_kind': s:SCHEMA_KIND,
\     'matcher': s:SCHEMA_MATCHER,
\     'gather_candidates': {
\       'type': v:t_func,
\     },
\     'on_source_enter': {
\       'type': v:t_func,
\       'optional': 1,
\     },
\     'on_source_leave': {
\       'type': v:t_func,
\       'optional': 1,
\     },
\     'on_action': {
\       'type': v:t_func,
\       'optional': 1,
\     },
\     'special_char_p': {
\       'type': v:t_func,
\       'optional': 1,
\     },
\     'valid_for_acc_p': {
\       'type': v:t_func,
\       'optional': 1,
\     },
\   },
\ }








" Variables  "{{{1

" Contains the information of a ku session.
" See s:new_session() for the details of content.
if !exists('s:session')
  let s:session = {}
endif

" buffer number of the ku buffer
if !exists('s:ku_bufnr')
  let s:ku_bufnr = -1
endif







" Interface  "{{{1
function! ku#define_default_ui_key_mappings() abort  "{{{2
  nmap <buffer> <C-c> <Plug>(ku-quit-session)
  nmap <buffer> <C-i> <Plug>(ku-choose-action)
  nmap <buffer> <C-m> <Plug>(ku-do-default-action)
  nmap <buffer> <Return> <Plug>(ku-do-default-action)
  nmap <buffer> <Tab> <Plug>(ku-choose-action)

  imap <buffer> <C-c> <Plug>(ku-quit-session)
  imap <buffer> <C-i> <Plug>(ku-choose-action)
  imap <buffer> <C-m> <Plug>(ku-do-default-action)
  imap <buffer> <Return> <Plug>(ku-do-default-action)
  imap <buffer> <Tab> <Plug>(ku-choose-action)

  imap <buffer> <BS>  <Plug>(ku-delete-backward-char)
  imap <buffer> <C-h>  <Plug>(ku-delete-backward-char)
  imap <buffer> <C-u>  <Plug>(ku-delete-backward-line)
  imap <buffer> <C-w>  <Plug>(ku-delete-backward-component)
endfunction




function! ku#request_update_candidates() abort  "{{{2
  if s:ku_active_p()
    let complete_info = complete_info(['mode'])
    if complete_info.mode != ''
      call feedkeys(s:KEYS_TO_START_COMPLETION, 'n')
    endif
  endif
endfunction




function! ku#restart() abort  "{{{2
  if empty(s:session)
    echohl ErrorMsg
    echo 'ku: Not started yet'
    echohl NONE
    return s:FALSE
  endif
  let last_source = s:session.source
  let last_pattern = s:remove_prompt(s:session.last_pattern_raw)
  let options = extend({ 'initial_pattern': last_pattern },
  \                    s:session.options,
  \                    'keep')
  return ku#start(last_source, options)
endfunction




function! ku#start(source, options = {}) abort  "{{{2
  if s:ku_active_p()
    echohl ErrorMsg
    echo 'ku: Already active'
    echohl NONE
    return s:FALSE
  endif

  let errors = ku#schema#validate(a:source, s:SCHEMA_SOURCE)
  if !empty(errors)
    echoerr 'ku: Invalid format for source'
    for error in errors
      echoerr error
    endfor
    return s:FALSE
  endif

  " Initialze session.
  let s:session = s:new_session(a:source, a:options)

  " Open or create the ku buffer.
  let v:errmsg = ''
  if bufexists(s:ku_bufnr)
    topleft split
    if v:errmsg != ''
      return s:FALSE
    endif
    silent execute s:ku_bufnr 'buffer'
  else
    topleft new
    if v:errmsg != ''
      return s:FALSE
    endif
    let s:ku_bufnr = bufnr('')
    call s:initialize_ku_buffer()
  endif
  2 wincmd _

  " Set some options.
    " Ensure to allow backspacing after ACC, etc.  These features move the
    " cursor in Insert mode and such operation starts new Insert mode, so that
    " backspacing may not work after ACC, etc if the value of 'backspace' is
    " not properly set.
  set backspace=eol,indent,start
    " Ensure to show ins-completion-menu while automatic completion.
  set completeopt=menu,menuone
  set noequalalways

  " Reset the content of the ku buffer.
  " BUGS: To avoid unexpected behavior caused by automatic completion of the
  "       prompt, append the prompt and {initial-pattern} at this timing.
  "       Automatic completion is implemented by feedkeys() and starting
  "       Insert mode is also implemented by feedkeys().  These feedings must
  "       be done carefully.
  silent % delete _
  normal! o
  let initial_pattern = get(a:options, 'initial_pattern', '')
  call setline(s:LNUM_STATUS, 'Source: ' . a:source.name)
  call setline(s:LNUM_PATTERN, s:PROMPT . initial_pattern)
  execute 'normal!' s:LNUM_PATTERN . 'G'

  " Start Insert mode.
  " BUGS: :startinsert! may not work with append()/setline()/:put.
  "       If the typeahead buffer is empty, ther is no problem.
  "       Otherwise, :startinsert! behaves as '$i', not 'A',
  "       so it is inconvenient.
  " BUGS: It's not possible to emulate the same input by
  "       s:consume_typeahead_buffer() and feedkeys().  Because there is no
  "       way to get information on the source of an input character, for
  "       example, typed character, mapped character, etc.
  let typeahead_buffer = s:consume_typeahead_buffer()
  call feedkeys('A' . typeahead_buffer, 'n')

  if has_key(a:source, 'on_source_enter')
    call a:source.on_source_enter()
  endif

  return s:TRUE
endfunction




function! ku#take_action(action_name = 0) abort  "{{{2
  if !s:ku_active_p()
    echohl ErrorMsg
    echo 'ku: Not active'
    echohl NONE
    return s:FALSE
  endif

  let candidate = s:session.completed_item isnot 0
  \             ? s:session.completed_item
  \             : s:guess_candidate()
  if candidate is 0
    " Ignore.  Assumes that error message is already displayed by caller.
    return s:FALSE
  endif

  let kind = s:kind_from_candidate(candidate)
  let action_name = a:action_name is 0
  \               ? s:choose_action(candidate, kind)
  \               : a:action_name

  if action_name isnot 0
    if has_key(s:session.source, 'on_action')
      let candidate = s:session.source.on_action(candidate)
    endif
  endif

  " Close the ku window, because some kind of actions does something on the
  " current buffer/window and user expects that such actions do something on
  " the buffer/window which was the current one until the ku buffer became
  " active.
  call s:quit_session()

  if action_name is 0
    " In these cases, error messages are already noticed by other functions.
    return s:FALSE
  endif

  let error = s:do_action(action_name, candidate, kind)
  if error isnot 0
    echohl ErrorMsg
    echomsg error
    echohl NONE
    return s:FALSE
  endif

  return s:TRUE
endfunction








" Misc.  "{{{1
function! ku#_do_action(action_name, candidate) abort  "{{{2
  let kind = s:kind_from_candidate(a:candidate)
  return s:do_action(a:action_name, a:candidate, kind)
endfunction




function! ku#_omnifunc(findstart, base) abort  "{{{2
  if a:findstart
    " FIXME: For in-line completion.

    let s:session.last_candidates = []

    " To determine whether the content of the current line is inserted by
    " Vim's completion or not, return 0 to remove the prompt by completion.
    return 0
  else
    let source = s:session.source
    let pattern = s:remove_prompt(a:base)
    let candidates = source.gather_candidates(pattern)
    let limit = get(s:session.options, 'limit', -1)
    let s:session.last_candidates =
    \   source.matcher.match_candidates(candidates, pattern, limit)
    return s:session.last_candidates
  endif
endfunction




function! s:acc_text(line, sep, candidates) abort  "{{{2
  " ACC = Automatic Component Completion

  let user_input_raw = s:remove_prompt(a:line)
  let line_components = split(user_input_raw, a:sep, s:TRUE)

  " Find a candidate which has the same components but the last 2 ones of
  " line_components.  Because line_components[-1] is always empty and
  " line_components[-2] is almost imperfect name of a component.
  "
  " Example:
  "
  " (a) a:line ==# 'usr/share/m/',
  "     line_components ==# ['usr', 'share', 'm', '']
  "
  "     The 1st candidate prefixed with 'usr/share/' will be used for ACC.
  "     If 'usr/share/man/man1/' is found in this way,
  "     the completed text will be 'usr/share/man'.
  "
  " (b) a:line ==# 'u/'
  "     line_components ==# ['u', '']
  "
  "     The 1st candidate is alaways used for ACC.
  "     If 'usr/share/man/man1/' is found in this way,
  "     the completion text will be 'usr'.
  "
  " (c) a:line ==# 'm/'
  "     line_components ==# ['m', '']
  "
  "     The 1st candidate is alaways used for ACC.
  "     If 'usr/share/man/man1/' is found in this way,
  "     the completion text will be 'usr/share/man'.
  "     Because user seems to want to complete till the component which
  "     matches to 'm'.
  for candidate in a:candidates
    let candidate_components = split(candidate.word, '\V' . a:sep, s:TRUE)

    if len(line_components) < 2
      echoerr 'ku:e2: Assumption on ACC is failed: ' . string(line_components)
      continue
    elseif len(line_components) == 2
      " OK - the case (b) or (c)
    elseif len(line_components) - 2 <= len(candidate_components)
      for i in range(len(line_components) - 2)
        if line_components[i] != candidate_components[i]
          break
        endif
      endfor
      if line_components[i] != candidate_components[i]
        continue
      endif
      " OK - the case (a)
    else
      continue
    endif

    if has_key(s:session.source, 'valid_for_acc_p')
    \  && !s:session.source.valid_for_acc_p(candidate, a:sep)
      continue
    endif

    " Find the index of the last component to be completed.
    "
    " For example, with candidate ==# 'usr/share/man/man1':
    "   If line_components ==# ['u', '']:
    "     c == 2 - 2
    "     i == 0
    "     t ==# 'usr/share/man/man1'
    "            ^
    "   If line_components ==# ['m', '']:
    "     c == 2 - 2
    "     i == 10
    "     t ==# 'usr/share/man/man1'
    "                      ^
    "   If line_components ==# ['usr', 'share', 'm', '']:
    "     c == 4 - 2
    "     i == 0
    "     t ==# 'man/man1'
    "            ^
      " Count of 'prefix' components in line_components.
      " 'prefix' components are all of line_components but the last two ones.
    let c = len(line_components) - 2
      " Pattern for the partially typed component = line_components[-2].
    let p = '\c' . s:make_skip_regexp(line_components[-2])
      " Tail of candidate.word without 'prefix' component in line_components.
    let t = join(candidate_components[(c):], a:sep)

    let i = matchend(t, p)
    if i < 0  " Partially typed component doesn't match for this candidate.
      continue  " Try next one.
    endif
    let j = stridx(t, a:sep, i)
    if 0 <= j
      " Several candidate_components are matched for ACC.
      let index_to_preceding_char_to_SEP = -(len(t) - j + 1)
      let index_to_the_tail_of_completed_text = index_to_preceding_char_to_SEP
      let result = candidate.word[:index_to_the_tail_of_completed_text]
    else
      " All of candidate_components are matched for ACC.
      let result = join(candidate_components, a:sep)
    endif

    return result
  endfor

  return ''  " No proper candidate found
endfunction




function! s:choose_action(candidate, kind) abort  "{{{2
  " Prompt      Candidate Source
  "    |          |         |
  "   _^_______  _^______  _^__
  "   Candidate: Makefile (file)
  "   ^C cancel      ^O open        ...
  "   What action?   ~~ ~~~~
  "   ~~~~~~~~~~~~    |   |
  "         |         |   |
  "      Message     Key  Action
  "
  " Here "Prompt" is highlighted with kuChoosePrompt,
  " "Candidate" is highlighted with kuChooseCandidate, and so forth.
  let KEY_TABLE = s:composite_key_table(a:kind)
  " "Candidate: {candidate} ({source})"
  echohl NONE
  echo ''
  echohl kuChoosePrompt
  echon 'Candidate'
  echohl NONE
  echon ': '
  echohl kuChooseCandidate
  echon a:candidate.word
  echohl NONE
  echon ' ('
  echohl kuChooseSource
  echon s:session.source.name
  echohl NONE
  echon ')'
  call s:list_key_bindings_sorted_by_action_name(KEY_TABLE)
  echohl kuChooseMessage
  echo 'What action? '
  echohl NONE

  " Take user input.
  let k = s:get_key()
  redraw  " clear the menu message lines to avoid hit-enter prompt.

  " Return the action bound to the key k.
  if has_key(KEY_TABLE, k)
    return KEY_TABLE[k]
  else
    " FIXME: loop to rechoose?
    echo 'The key' string(k) 'is not associated with any action'
    \    '-- nothing happened.'
    return 0
  endif
endfunction




function! s:list_key_bindings_sorted_by_action_name(key_table) abort  "{{{2
  " ACTIONS => {
  "   'keys': [[key_value, key_repr], ...],
  "   'label': label
  " }
  let ACTIONS = {}
  for [key, action] in items(a:key_table)
    if !has_key(ACTIONS, action)
      let ACTIONS[action] = {'keys': []}
    endif
    call add(ACTIONS[action].keys, [key, strtrans(key)])
  endfor
  for _ in values(ACTIONS)
    call sort(_.keys)
    let _.label = join(map(copy(_.keys), 'v:val[1]'), ' ')
  endfor
  silent! unlet _

  " key  action
  " ---  ------
  "  ^H  left  
  " -----------
  "   cell
  let ACTION_NAMES = sort(keys(ACTIONS), 's:compare_ignorecase')
  let MAX_ACTION_NAME_WIDTH = max(map(keys(ACTIONS), 'len(v:val)'))
  let MAX_LABEL_WIDTH = max(map(values(ACTIONS), 'len(v:val.label)'))
  let MAX_CELL_WIDTH = MAX_ACTION_NAME_WIDTH + 1 + MAX_LABEL_WIDTH
  let SPACER = '   '
  let COLUMNS = (&columns + len(SPACER) - 1) / (MAX_CELL_WIDTH + len(SPACER))
  let COLUMNS = max([COLUMNS, 1])
  let N = len(ACTIONS)
  let ROWS = N / COLUMNS + (N % COLUMNS != 0)

  for row in range(ROWS)
    for column in range(COLUMNS)
      let i = column * ROWS + row
      if !(i < N)
        continue
      endif

      echon column == 0 ? "\n" : SPACER

      echohl kuChooseAction
      let _ = ACTION_NAMES[i]
      echon _
      echohl NONE
      echon repeat(' ', MAX_ACTION_NAME_WIDTH - len(_))

      echohl kuChooseKey
      echon ' '
      let _ = ACTIONS[ACTION_NAMES[i]].label
      echon _
      echohl NONE
      echon repeat(' ', MAX_LABEL_WIDTH - len(_))
    endfor
  endfor

  return
endfunction




function! s:compare_ignorecase(x, y) abort  "{{{2
  " Comparing function for sort() to do consistently case-insensitive sort.
  "
  " sort(list, 1) does case-insensitive sort,
  " but its result may not be in a consistent order.
  " For example,
  " sort(['b', 'a', 'B', 'A'], 1) may return ['a', 'A', 'b', 'B'],
  " sort(['b', 'A', 'B', 'a'], 1) may return ['A', 'a', 'b', 'B'],
  " and so forth.
  "
  " With this function, sort() always return ['A', 'a', 'B', 'b'].
  return a:x <? a:y ? -1
  \    : (a:x >? a:y ? 1
  \    : (a:x <# a:y ? -1
  \    : (a:x ># a:y ? 1
  \    : 0)))
endfunction




function! s:complete_the_prompt() abort  "{{{2
  call setline('.', s:PROMPT . getline('.'))
  return
endfunction




function! s:composite_key_table(kind) abort  "{{{2
  let key_table = {}
  let kind = a:kind

  while 1
    call extend(key_table, kind.key_table)
    if !has_key(kind, 'prototype')
      break
    endif
    let kind = kind.prototype
  endwhile

  return key_table
endfunction





function! s:consume_typeahead_buffer() abort  "{{{2
  let buffer = ''

  while s:TRUE
    let c = getchar(0)
    if c is 0
      break
    endif
    let buffer .= type(c) is v:t_number ? nr2char(c) : c
  endwhile

  return buffer
endfunction




function! s:contains_the_prompt_p(s) abort  "{{{2
  return len(s:PROMPT) <= len(a:s) && a:s[:len(s:PROMPT) - 1] ==# s:PROMPT
endfunction




function! s:do_action(action_name, candidate, kind) abort  "{{{2
  let Action = s:find_action(a:kind, a:action_name)
  if Action is 0
    return 'There is no such action:' string(a:action_name)
  endif
  return Action(a:candidate)
endfunction




function! s:find_action(kind, action_name) abort  "{{{2
  let kind = a:kind

  while 1
    if has_key(kind.action_table, a:action_name)
      return kind.action_table[a:action_name]
    endif
    if !has_key(kind, 'prototype')
      break
    endif
    let kind = kind.prototype
  endwhile

  return 0
endfunction




function! s:get_char(...) abort  "{{{2
  " Rich version of getchar()

  let n = call('getchar', a:000)
  let _ = {}

  " Normalized result of getchar()
  let _.s = type(n) is v:t_number ? nr2char(n) : n

  " Characters in s
  let _.cs = map(range(len(_.s)), '_.s[v:val]')

  " Bytes corresponding to cs
  let _.bs = map(copy(_.cs), 'char2nr(v:val)')

  return _
endfunction




function! s:get_key() abort  "{{{2
  " Alternative getchar() to get a logical key such as <F1> and <M-{x}>.

  let k1 = s:get_char()

  if k1.s ==# "\<Esc>"
    let k2 = s:get_char(0)
    return k1.s . k2.s
  else
    return k1.s
  endif
endfunction




function! s:guess_candidate() abort  "{{{2
  let current_pattern_raw = getline(s:LNUM_PATTERN)

  if current_pattern_raw !=# s:session.last_pattern_raw
    " current_pattern_raw seems to be inserted by Vim's completion,
    " so user seemed to select a candidate by Vim's completion.
    for candidate in s:session.last_candidates
      if current_pattern_raw ==# candidate.word
        return candidate
      endif
    endfor

    echoerr 'ku:e1: No match found in s:session.last_candidates'
    echoerr '  current_pattern_raw' string(current_pattern_raw)
    echoerr '  s:session.last_pattern_raw'
    \          string(s:session.last_pattern_raw)
    echoerr '  s:session.last_candidates'
    \          string(s:session.last_candidates)
    return 0
  endif

  " current_pattern_raw seems NOT to be inserted by Vim's completion, but ...
  if 0 < len(s:session.last_candidates)
    " There are 1 or more candidates -- user seems to want to take action on
    " the first one.
    return s:session.last_candidates[0]
  endif

  " There is no candidate -- user seems to want to take action on
  " current_pattern_raw with fake sources.
  return {
  \   'word': s:remove_prompt(current_pattern_raw),
  \   'user_data': {},
  \ }
endfunction




function! s:initialize_ku_buffer() abort  "{{{2
  " The current buffer is initialized.

  " Basic settings.
  setlocal bufhidden=hide
  setlocal buftype=nofile
  setlocal nobuflisted
  setlocal noswapfile
  setlocal omnifunc=ku#_omnifunc
  silent file `=s:KU_BUFFER_NAME`

  " Autocommands.
  augroup plugin-ku
    autocmd BufLeave <buffer>  call s:quit_session()
    autocmd BufUnload <buffer>  let s:ku_bufnr = -1
    autocmd CompleteDonePre <buffer>  call s:on_CompleteDonePre()
    autocmd CursorMovedI <buffer>  call s:on_CursorMovedI()
    autocmd InsertEnter <buffer>  call s:on_InsertEnter()
    autocmd TextChangedP <buffer>  call s:on_TextChangedP()
    autocmd WinLeave <buffer>  call s:quit_session()
  augroup END

  " Key mappings - fundamentals.
  nnoremap <buffer> <silent> <SID>(choose-action)
  \        :<C-u>call ku#take_action()<Return>
  nnoremap <buffer> <silent> <SID>(do-default-action)
  \        :<C-u>call ku#take_action('default')<Return>
  nnoremap <buffer> <silent> <SID>(quit-session)
  \        :<C-u>call <SID>quit_session()<Return>
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

  nnoremap <buffer> <script> <Plug>(ku-choose-action)
  \        <SID>(choose-action)
  nnoremap <buffer> <script> <Plug>(ku-do-default-action)
  \        <SID>(do-default-action)
  nnoremap <buffer> <script> <Plug>(ku-quit-session)
  \        <SID>(quit-session)

  inoremap <buffer> <script> <Plug>(ku-choose-action)
  \        <SID>(accept-completion)<Esc><SID>(choose-action)
  inoremap <buffer> <script> <Plug>(ku-do-default-action)
  \        <SID>(accept-completion)<Esc><SID>(do-default-action)
  inoremap <buffer> <script> <Plug>(ku-quit-session)
  \        <Esc><SID>(quit-session)

  inoremap <buffer> <script> <Plug>(ku-delete-backward-char)
  \        <SID>(delete-backward-char)
  inoremap <buffer> <script> <Plug>(ku-delete-backward-line)
  \        <SID>(delete-backward-line)
  inoremap <buffer> <script> <Plug>(ku-delete-backward-component)
  \        <SID>(delete-backward-component)
  " <C-n>/<C-p> ... Vim doesn't expand these keys in Insert mode completion.

  " User's initialization.
  setfiletype ku

  " Key mappings - user interface.
  if !exists('#FileType#ku') && !exists('b:did_ftplugin')
    call ku#define_default_ui_key_mappings()
  endif

  return
endfunction




function! s:keys_to_complete() abort  "{{{2
  let cursor_column = col('.')
  let line = getline('.')

  " The order of the following conditions are important.
  if !s:contains_the_prompt_p(line)
    " Complete the prompt if it doesn't exist for some reasons.
    let keys = repeat("\<Right>", len(s:PROMPT))
    call s:complete_the_prompt()
  elseif cursor_column <= len(s:PROMPT)
    " Move the cursor out of the prompt if it is in the prompt.
    let keys = repeat("\<Right>", len(s:PROMPT) - cursor_column + 1)
  elseif len(line) < cursor_column && cursor_column != s:session.last_column
    let sep = line[-1:]
    " New character is inserted.  Let's complete automatically.
    if !s:session.inserted_by_acc_p
    \  && len(s:PROMPT) + 2 <= len(line)
    \  && has_key(s:session.source, 'special_char_p')
    \  && s:session.source.special_char_p(sep)
      " (1) The last inserted character is not inserted by ACC.
      " (2) It is a special character for current source
      " (3) It seems not to be the 1st one in line.
      "
      " The (3) is necessary to input a special character as the 1st character
      " in line.  For example, without this condition, user cannot input the
      " 1st '/' of an absolute path like '/usr/local/bin' if '/' is a special
      " character.
      "
      " FIXME: Is s:session.last_candidates reliable?  If user types several
      "        characters quickely, Vim doesn't call 'omnifunc' for all but
      "        the last character.  So here we have to ensure that
      "        s:session.last_candidates contains reliable value,
      "        by calling 'omnifunc' appropriately.
      "
      " FIXME: But what should we do if user quickely types two or more
      "        special character?  It's hard to make
      "        s:session.last_candidates reliable, isn't it?
      "        At this moment, we simply ignore such case.
      let acc_text = s:acc_text(line, sep, s:session.last_candidates)
      let s:session.inserted_by_acc_p = s:TRUE
      if acc_text != ''
        " The last special character must be inserted in this way to forcedly
        " show the completion menu.
          " FIXME: Should we update l:line for s:session.last_pattern_raw?
        call setline('.', acc_text)
        let keys = "\<End>" . sep
        let s:session.inserted_by_acc_p = s:TRUE
      else
        let keys = s:KEYS_TO_START_COMPLETION
        let s:session.inserted_by_acc_p = s:FALSE
      endif
    else
      let keys = s:KEYS_TO_START_COMPLETION
      let s:session.inserted_by_acc_p = s:FALSE
    endif
  else
    let keys = ''
  endif

  let s:session.last_column = cursor_column
  let s:session.last_pattern_raw = line
  return keys
endfunction




function! s:keys_to_delete_backward_component() abort  "{{{2
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
    if has_key(s:session.source, 'special_char_p')
      for i in range(len(line) - 2, 0, -1)
        if s:session.source.special_char_p(line[i:i])
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




function! s:kind_from_candidate(candidate) abort  "{{{2
  return has_key(a:candidate, 'ku_kind')
  \      ? a:candidate.ku_kind
  \      : s:session.source.default_kind
endfunction




function! s:ku_active_p() abort  "{{{2
  return bufexists(s:ku_bufnr) && bufwinnr(s:ku_bufnr) != -1
endfunction




function! s:make_skip_regexp(s) abort  "{{{2
  " 'abc' ==> '\Va*b*c'
  " '\!/' ==> '\V\\*!*/'
  " Here '*' means '\.\{-}'
  let [xs, last] = [a:s[:-2], a:s[-1:]]
  return '\V'
  \    . substitute(escape(xs, '\'), '\%(\\\\\|[^\\]\)\zs', '\\.\\{-}', 'g')
  \    . escape(last, '\')
endfunction




function! s:new_session(source, options) abort  "{{{2
  let session = {}

  let session.inserted_by_acc_p = s:FALSE
  let session.completed_item = 0
  let session.last_candidates = []
  let session.last_column = -1
  let session.last_pattern_raw = ''
  let session.now_quitting_p = s:FALSE
  let session.options = a:options
  let session.original_backspace = &backspace
  let session.original_completeopt = &completeopt
  let session.original_curwinnr = winnr()
  let session.original_equalalways = &equalalways
  let session.source = a:source

  return session
endfunction




function! s:on_CompleteDonePre() abort  "{{{2
  let complete_info = complete_info(['selected'])
  let s:session.completed_item = complete_info['selected'] >= 0
  \                            ? copy(v:completed_item)
  \                            : 0
endfunction




function! s:on_CursorMovedI() abort  "{{{2
  call feedkeys(s:keys_to_complete(), 'n')
endfunction




function! s:on_InsertEnter() abort  "{{{2
  let s:session.inserted_by_acc_p = s:FALSE
  let s:session.last_column = -1
  let s:session.last_pattern_raw = ''
  call feedkeys(s:keys_to_complete(), 'n')
endfunction




function! s:on_TextChangedP() abort  "{{{2
  let complete_info = complete_info(['selected'])
  if complete_info['selected'] == -1
    call feedkeys(s:keys_to_complete(), 'n')
  endif
endfunction




function! s:quit_session() abort  "{{{2
  " Assumption: The current buffer is the ku buffer.
  " We have to check s:session.now_quitting_p to avoid unnecessary
  " :close'ing, because s:quit_session() may be called recursively.
  if s:session.now_quitting_p
    return s:FALSE
  endif

  let s:session.now_quitting_p = s:TRUE
  if has_key(s:session.source, 'on_source_leave')
    call s:session.source.on_source_leave()
  endif
  close

  let &backspace = s:session.original_backspace
  let &equalalways = s:session.original_equalalways
  let &completeopt = s:session.original_completeopt
  execute s:session.original_curwinnr 'wincmd w'
  let s:session.now_quitting_p = s:FALSE

  return s:TRUE
endfunction




function! s:remove_prompt(s) abort  "{{{2
  return s:contains_the_prompt_p(a:s) ? a:s[len(s:PROMPT):] : a:s
endfunction








" __END__  "{{{1
" vim: foldmethod=marker
