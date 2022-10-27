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

let s:SOURCE_SPEC = {
\   'constraint': 'struct',
\   'body': {
\     'gather_candidates': {
\       'constraint': 'type',
\       'body': v:t_func,
\     },
\     'name': {
\       'constraint': 'type',
\       'body': v:t_string,
\     },
\     'kind': {
\       'constraint': 'struct',
\       'body': {
\         'action_table': {
\           'constraint': 'dictionary',
\           'body': {
\             'constraint': 'type',
\             'body': v:t_func,
\           }
\         },
\         'key_table': {
\           'constraint': 'dictionary',
\           'body': {
\             'constraint': 'type',
\             'body': v:t_string,
\           }
\         },
\       },
\     },
\     'on_source_enter': {
\       'constraint': 'type',
\       'body': v:t_func,
\     },
\     'on_source_leave': {
\       'constraint': 'type',
\       'body': v:t_func,
\     },
\     'special_char_p': {
\       'constraint': 'type',
\       'body': v:t_func,
\     },
\     'valid_for_acc_p': {
\       'constraint': 'type',
\       'body': v:t_func,
\     },
\   },
\ }








" Variables  "{{{1

" Contains the information of a ku session.
" See s:new_session() for the details of content.
let s:session = {}

" buffer number of the ku buffer
let s:ku_bufnr = -1

if !exists('g:ku_limit_candidates')
  let g:ku_limit_candidates = 1000
endif








" Interface  "{{{1
function! ku#define_default_ui_key_mappings(override_p) abort  "{{{2
  " Define key mappings for the current buffer.
  let args = a:override_p ? '<buffer>' : '<unique> <buffer>'

  for command in ['nmap', 'imap']
    execute command args '<C-c>' '<Plug>(ku-quit-session)'
    execute command args '<C-c>' '<Plug>(ku-quit-session)'
    execute command args '<C-i>' '<Plug>(ku-choose-action)'
    execute command args '<C-m>' '<Plug>(ku-do-default-action)'
    execute command args '<Enter>' '<Plug>(ku-do-default-action)'
    execute command args '<Return>' '<Plug>(ku-do-default-action)'
    execute command args '<Tab>' '<Plug>(ku-choose-action)'
  endfor

  execute 'imap' args '<BS>' '<Plug>(ku-delete-backward-char)'
  execute 'imap' args '<C-h>' '<Plug>(ku-delete-backward-char)'
  execute 'imap' args '<C-u>' '<Plug>(ku-delete-backward-line)'
  execute 'imap' args '<C-w>' '<Plug>(ku-delete-backward-component)'

  return
endfunction




function! ku#do_action(action_name, candidate) abort  "{{{2
  let kind = s:kind_from_candidate(a:candidate)
  return s:do_action(a:action_name, a:candidate, kind)
endfunction




function! ku#refresh_candidates() abort  "{{{2
  if !s:ku_active_p()
    return s:FALSE
  endif

  let complete_info = complete_info(['mode'])
  if complete_info.mode == ''
    return s:FALSE
  endif

  call feedkeys(s:KEYS_TO_START_COMPLETION, 'n')
  return s:TRUE
endfunction




function! ku#restart()  "{{{2
  if empty(s:session)
    echohl ErrorMsg
    echo 'ku: Not started yet'
    echohl NONE
    return s:FALSE
  endif
  let last_source = s:session.source
  let last_pattern = s:remove_prompt(s:session.last_pattern_raw)
  return ku#start(last_source, last_pattern)
endfunction




function! ku#start(source, initial_pattern = '') abort  "{{{2
  if s:ku_active_p()
    echohl ErrorMsg
    echo 'ku: Already active'
    echohl NONE
    return s:FALSE
  endif

  let errors = ku#spec#validate(a:source, s:SOURCE_SPEC)
  if !empty(errors)
    echoerr 'ku: Invalid format for source'
    for error in errors
      echoerr error
    endfor
    return s:FALSE
  endif

  " Initialze session.
  let s:session = s:new_session(a:source)

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
  call setline(s:LNUM_STATUS, 'Source: ' . a:source.name)
  call setline(s:LNUM_PATTERN, s:PROMPT . a:initial_pattern)
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

  call a:source.on_source_enter()

  return s:TRUE
endfunction




function! ku#take_action(action_name = 0) abort  "{{{2
  if !s:ku_active_p()
    echohl ErrorMsg
    echo 'ku: Not active'
    echohl NONE
    return s:FALSE
  endif

  let candidate = has_key(v:completed_item, 'user_data')
  \               && type(v:completed_item.user_data) == v:t_dict
  \               && has_key(v:completed_item.user_data, 'ku__completed_p')
  \               && v:completed_item.user_data.ku__completed_p
  \             ? v:completed_item
  \             : s:guess_candidate()
  if candidate is 0
    " Ignore.  Assumes that error message is already displayed by caller.
    return s:FALSE
  endif

  let kind = s:kind_from_candidate(candidate)
  let action_name = a:action_name is 0
  \               ? s:choose_action(candidate, kind)
  \               : a:action_name

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
function! ku#_omnifunc(findstart, base) abort  "{{{2
  if a:findstart
    " FIXME: For in-line completion.

    let s:session.last_candidates = []

    " To determine whether the content of the current line is inserted by
    " Vim's completion or not, return 0 to remove the prompt by completion.
    return 0
  else
    let pattern = s:remove_prompt(a:base)
    let s:session.last_candidates = s:omnifunc_core(pattern)
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

    if !candidate.user_data.ku__source.valid_for_acc_p(candidate, a:sep)
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
  echon a:candidate.user_data.ku__source.name
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
    let buffer .= type(c) == type(0) ? nr2char(c) : c
  endwhile

  return buffer
endfunction




function! s:contains_the_prompt_p(s) abort  "{{{2
  return len(s:PROMPT) <= len(a:s) && a:s[:len(s:PROMPT) - 1] ==# s:PROMPT
endfunction




function! s:do_action(action_name, candidate, kind) abort  "{{{2
  let ActionFn = s:find_action(a:kind, a:action_name)
  if ActionFn is 0
    return 'There is no such action:' string(a:action_name)
  endif

  let source = a:candidate.user_data.ku__source
  let candidate = source.on_action(a:candidate)

  return ActionFn(candidate)
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
  let _.s = type(n) == type(0) ? nr2char(n) : n

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
  \   'user_data': {
  \     'ku__completed_p': s:FALSE,
  \     'ku__source': s:session.source,
  \   }
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
    autocmd InsertEnter <buffer>  call feedkeys(s:on_InsertEnter(), 'n')
    autocmd CursorMovedI <buffer>  call feedkeys(s:on_CursorMovedI(), 'n')
    autocmd BufLeave <buffer>  call s:quit_session()
    autocmd WinLeave <buffer>  call s:quit_session()
    autocmd BufUnload <buffer>  let s:ku_bufnr = -1
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
  \        pumvisible() ? '<C-y><C-u>' : '<C-u>'
  inoremap <buffer> <expr> <SID>(delete-backward-component)
  \ (pumvisible() ? '<C-y>' : '')
  \ . <SID>keys_to_delete_backward_component()

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
  if !(exists('#FileType#ku') || exists('b:did_ftplugin'))
    call ku#define_default_ui_key_mappings(s:TRUE)
  endif

  return
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
    for i in range(len(line) - 2, 0, -1)
      if s:session.source.special_char_p(line[i:i])
        let num_chars = strchars(line[i + 1:])
        return repeat("\<BS>", num_chars)
      endif
    endfor
    " No component separator - delete everything.
    return "\<C-u>"
  else
    " Don't consider cases that the cursor doesn't point the end of the
    " current line.
    return "\<C-w>"
  endif
endfunction




function! s:kind_from_candidate(candidate) abort  "{{{2
  return has_key(a:candidate.user_data, 'ku__kind')
  \      ? a:candidate.user_data.ku__kind
  \      : a:candidate.user_data.ku__source.kind
endfunction




function! s:ku_active_p() abort  "{{{2
  return bufexists(s:ku_bufnr) && bufwinnr(s:ku_bufnr) != -1
endfunction




function! s:make_skip_regexp(s) abort  "{{{2
  " 'abc' ==> '\Va*b*c'
  " '\!/' ==> '\V\\*!*/'
  " Here '*' means '\.\{-}'
  let [xs, last] = [a:s[:-2], a:s[-1:]]
  return ('\V'
  \       . substitute(escape(xs, '\'), '\%(\\\\\|[^\\]\)\zs', '\\.\\{-}', 'g')
  \       . escape(last, '\'))
endfunction




function! s:normalize_candidate(candidate, position, score)  "{{{2
  if !has_key(a:candidate, 'user_data')
    let a:candidate.user_data = {}
  endif
  let a:candidate.user_data.ku__completed_p = s:TRUE
  let a:candidate.user_data.ku__source = s:session.source
  if !has_key(a:candidate, 'ku__sort_priority')
    let a:candidate.ku__sort_priority = 0
  endif
  let a:candidate.ku__matching_position = a:position
  let a:candidate.ku__matching_score = a:score
endfunction




function! s:new_session(source) abort  "{{{2
  let session = {}

    " Use list to ensure returning different value for each time.
  let session.id = [localtime()]
  let session.inserted_by_acc_p = s:FALSE
  let session.last_column = -1
  let session.last_candidates = []
  let session.last_pattern_raw = ''
  let session.now_quitting_p = s:FALSE
  let session.original_backspace = &backspace
  let session.original_equalalways = &equalalways
  let session.original_completeopt = &completeopt
  let session.original_curwinnr = winnr()
  let session.original_winrestcmd = winrestcmd()
  let session.source = a:source

  return session
endfunction




function! s:omnifunc_compare_items(x, y)  "{{{2
  if a:x.ku__matching_position != a:y.ku__matching_position
    if a:x.ku__matching_score > a:y.ku__matching_score
      return -1
    endif
    if a:x.ku__matching_score < a:y.ku__matching_score
      return 1
    endif
  endif
  if a:x.ku__sort_priority < a:y.ku__sort_priority
    return -1
  endif
  if a:x.ku__sort_priority > a:y.ku__sort_priority
    return 1
  endif
  if a:x.word < a:y.word
    return -1
  endif
  if a:x.word > a:y.word
    return 1
  endif
  return 0
endfunction




function! s:omnifunc_core(pattern) abort  "{{{2
  let candidates = s:session.source.gather_candidates(a:pattern)

  if a:pattern == ''
    let candidates = candidates[:g:ku_limit_candidates]
    for candidate in candidates
      call s:normalize_candidate(candidate, [0, 0], 0)
    endfor
  else
    let [candidates, positions, scores] =
    \   matchfuzzypos(candidates, a:pattern, {'key': 'word', 'limit': g:ku_limit_candidates})
    for i in range(len(candidates))
      call s:normalize_candidate(candidates[i], positions[i], scores[i])
    endfor
  endif

  call sort(candidates, function('s:omnifunc_compare_items'))

  return candidates
endfunction




function! s:on_CursorMovedI() abort  "{{{2
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
    if (!s:session.inserted_by_acc_p)
    \  && len(s:PROMPT) + 2 <= len(line)
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




function! s:on_InsertEnter() abort  "{{{2
  let s:session.inserted_by_acc_p = s:FALSE
  let s:session.last_column = -1
  let s:session.last_pattern_raw = ''
  return s:on_CursorMovedI()
endfunction




function! s:quit_session() abort  "{{{2
  " Assumption: The current buffer is the ku buffer.

  " We have to check s:session.now_quitting_p to avoid unnecessary
  " :close'ing, because s:quit_session() may be called recursively.
  if s:session.now_quitting_p
    return s:FALSE
  endif

  let s:session.now_quitting_p = s:TRUE
  call s:session.source.on_source_leave()
  close

  let &backspace = s:session.original_backspace
  let &equalalways = s:session.original_equalalways
  let &completeopt = s:session.original_completeopt
  execute s:session.original_curwinnr 'wincmd w'
  execute s:session.original_winrestcmd
  let s:session.now_quitting_p = s:FALSE

  return s:TRUE
endfunction




function! s:remove_prompt(s) abort  "{{{2
  return s:contains_the_prompt_p(a:s) ? a:s[len(s:PROMPT):] : a:s
endfunction




" __END__  "{{{1
" vim: foldmethod=marker
