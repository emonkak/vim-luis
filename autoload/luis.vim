let s:SCHEMA_KIND = {
\   'type': 'struct',
\   'properties': {
\     'name': {
\       'type': v:t_string,
\     },
\     'action_table': {
\       'type': 'dict',
\       'item': {
\         'type': v:t_func,
\       },
\     },
\     'key_table': {
\       'type': 'dict',
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
\      'filter_candidates': {
\        'type': v:t_func,
\      },
\      'normalize_candidate': {
\        'type': v:t_func,
\      },
\      'sort_candidates': {
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
\     'on_action': {
\       'type': v:t_func,
\       'optional': 1,
\     },
\     'on_preview': {
\       'type': v:t_func,
\       'optional': 1,
\     },
\     'on_source_enter': {
\       'type': v:t_func,
\       'optional': 1,
\     },
\     'on_source_leave': {
\       'type': v:t_func,
\       'optional': 1,
\     },
\     'is_special_char': {
\       'type': v:t_func,
\       'optional': 1,
\     },
\     'is_valid_for_acc': {
\       'type': v:t_func,
\       'optional': 1,
\     },
\   },
\ }

let s:SCHEMA_SESSION = {
\   'type': 'struct',
\   'properties': {
\     'is_active': {
\       'type': v:t_func,
\     },
\     'quit': {
\       'type': v:t_func,
\     },
\     'source': s:SCHEMA_SOURCE,
\     'start': {
\       'type': v:t_func,
\     },
\     'restart': {
\       'type': v:t_func,
\     },
\     'reload_candidates': {
\       'type': v:t_func,
\       'optional': 1,
\     },
\   },
\ }

let s:session = {}

function! luis#do_action(kind, action_name, candidate) abort
  let Action = s:find_action(a:kind, a:action_name)
  if Action is 0
    return 'luis: Action ' . string(a:action_name) . ' is not defined'
  endif
  let context = { 'kind': a:kind, 'session': s:session }
  return Action(a:candidate, context)
endfunction

function! luis#restart() abort
  if empty(s:session)
    echohl ErrorMsg
    echo 'luis: Not started yet'
    echohl NONE
    return 0
  endif

  if s:session.is_active()
    echohl ErrorMsg
    echo 'luis: Already active'
    echohl NONE
    return 0
  endif

  call s:session.restart()

  return 1
endfunction

function! luis#start(new_session) abort
  if !empty(s:session) && s:session.is_active()
    echohl ErrorMsg
    echo 'luis: Already active'
    echohl NONE
    return 0
  endif

  let errors = luis#_validate_session(a:new_session)
  if !empty(errors)
    echoerr 'luis: Invalid session:' . "\n" . join(errors, "\n")
    return 0
  endif

  call a:new_session.start()

  let s:session = a:new_session

  return 1
endfunction

function! luis#take_action(...) abort
  if empty(s:session) || !s:session.is_active()
    echohl ErrorMsg
    echo 'luis: Not active'
    echohl NONE
    return 0
  endif

  let candidate = s:session.guess_candidate()
  if candidate is 0
    " Ignore. Assumes that error message is already displayed by caller.
    return 0
  endif

  let kind = s:kind_from_candidate(candidate, s:session.source.default_kind)
  let action_name = a:0 > 0 ? a:1 : s:choose_action(kind, candidate)

  if action_name isnot 0
    if has_key(s:session.source, 'on_action')
      call s:session.source.on_action(candidate, {
      \   'kind': kind,
      \   'session': s:session,
      \ })
    endif
  endif

  " Close the luis window, because some kind of actions does something on the
  " current buffer/window and user expects that such actions do something on
  " the buffer/window which was the current one until the luis buffer became
  " active.
  call s:session.quit()

  if action_name is 0
    " In these cases, error messages are already noticed by other functions.
    return 0
  endif

  let error = luis#do_action(kind, action_name, candidate)
  if error isnot 0
    echohl ErrorMsg
    echomsg error
    echohl NONE
    return 0
  endif

  return 1
endfunction

function! luis#_acc_text(pattern, candidates, source) abort
  " ACC = Automatic Component Completion
  let sep = a:pattern[-1:]
  let components = split(a:pattern, sep, 1)

  if len(components) < 2
    echoerr 'luis: Assumption on ACC is failed: ' . string(components)
    return ''
  endif

  " Find a candidate which has the same components but the last 2 ones of
  " components. Because components[-1] is always empty and
  " components[-2] is almost imperfect name of a component.
  "
  " Example:
  "
  " (a) a:pattern ==# 'usr/share/m/',
  "     components ==# ['usr', 'share', 'm', '']
  "
  "     The 1st candidate prefixed with 'usr/share/' will be used for ACC.
  "     If 'usr/share/man/man1/' is found in this way,
  "     the completed text will be 'usr/share/man'.
  "
  " (b) a:pattern ==# 'u/'
  "     components ==# ['u', '']
  "
  "     The 1st candidate is alaways used for ACC.
  "     If 'usr/share/man/man1/' is found in this way,
  "     the completion text will be 'usr'.
  "
  " (c) a:pattern ==# 'm/'
  "     components ==# ['m', '']
  "
  "     The 1st candidate is alaways used for ACC.
  "     If 'usr/share/man/man1/' is found in this way,
  "     the completion text will be 'usr/share/man'.
  "     Because user seems to want to complete till the component which
  "     matches to 'm'.
  for candidate in a:candidates
    let candidate_components = split(candidate.word, '\V' . sep, 1)

    if len(components) == 2
      " OK - the case (b) or (c)
    elseif len(components) - 2 <= len(candidate_components)
      for i in range(len(components) - 2)
        if components[i] != candidate_components[i]
          break
        endif
      endfor
      if components[i] != candidate_components[i]
        continue
      endif
      " OK - the case (a)
    else
      continue
    endif

    if has_key(a:source, 'is_valid_for_acc')
    \  && !a:source.is_valid_for_acc(candidate)
      continue
    endif

    " Find the index of the last component to be completed.
    "
    " For example, with candidate ==# 'usr/share/man/man1':
    "   If components ==# ['u', '']:
    "     c == 2 - 2
    "     i == 0
    "     t ==# 'usr/share/man/man1'
    "            ^
    "   If components ==# ['m', '']:
    "     c == 2 - 2
    "     i == 10
    "     t ==# 'usr/share/man/man1'
    "                      ^
    "   If components ==# ['usr', 'share', 'm', '']:
    "     c == 4 - 2
    "     i == 0
    "     t ==# 'man/man1'
    "            ^
    " Prefix components are all of components but the last two ones.
    let count_of_prefix = len(components) - 2
    " Tail of candidate.word without 'prefix' component in components.
    let tail = join(candidate_components[count_of_prefix:], sep)
    " Pattern for the partially typed component = components[-2].
    let pattern = '\c' . s:make_skip_regexp(components[-2])

    let i = matchend(tail, pattern)
    if i < 0
      continue  " Try next one
    endif

    let j = stridx(tail, sep, i)
    if j >= 0
      " Several candidate_components are matched for ACC.
      let tail_index = -(len(tail) - j + 1)
      return candidate.word[:tail_index]
    else
      " All of candidate_components are matched for ACC.
      return candidate.word
    endif
  endfor

  return ''
endfunction

function! luis#_validate_kind(kind) abort
  return luis#schema#validate(s:SCHEMA_KIND, a:kind)
endfunction

function! luis#_validate_matcher(matcher) abort
  return luis#schema#validate(s:SCHEMA_MATCHER, a:matcher)
endfunction

function! luis#_validate_source(source) abort
  return luis#schema#validate(s:SCHEMA_SOURCE, a:source)
endfunction

function! luis#_validate_session(source) abort
  return luis#schema#validate(s:SCHEMA_SESSION, a:source)
endfunction

function! luis#_reset_session() abort
  let s:session = {}
endfunction

function! s:choose_action(kind, candidate) abort
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
  " Here "Prompt" is highlighted with luisChoosePrompt,
  " "Candidate" is highlighted with luisChooseCandidate, and so forth.
  let key_table = s:composite_key_table(a:kind)
  " "Candidate: {candidate} ({source})"
  echohl NONE
  echo ''
  echohl luisChoosePrompt
  echon 'Candidate'
  echohl NONE
  echon ': '
  echohl luisChooseCandidate
  echon a:candidate.word
  echohl NONE
  echon ' ('
  echohl luisChooseKind
  echon a:kind.name
  echohl NONE
  echon ')'
  call s:list_key_bindings(key_table)
  echohl luisChooseMessage
  echo 'What action? '
  echohl NONE

  " Take user input.
  let k = s:get_key()
  redraw  " clear the menu message lines to avoid hit-enter prompt.

  " Return the action bound to the key k.
  if has_key(key_table, k)
    return key_table[k]
  else
    echo 'The key' string(k) 'is not associated with any action'
    \    '-- nothing happened.'
    return 0
  endif
endfunction

function! s:compare_ignorecase(x, y) abort
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
  \    : a:x >? a:y ? 1
  \    : a:x <# a:y ? -1
  \    : a:x ># a:y ? 1
  \    : 0
endfunction

function! s:composite_key_table(kind) abort
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

function! s:find_action(kind, action_name) abort
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

function! s:get_key() abort
  " Alternative getchar() to get a logical key such as <F1> and <M-{x}>.
  let k1 = getchar()
  let k1 = type(k1) is v:t_number ? nr2char(k1) : k1

  if k1 ==# "\<Esc>"
    let k2 = getchar(0)
    let k2 = type(k2) is v:t_number ? nr2char(k2) : k2
    return k1 . k2
  else
    return k1
  endif
endfunction

function! s:kind_from_candidate(candidate, default_kind) abort
  return has_key(a:candidate.user_data, 'kind')
  \      ? a:candidate.user_data.kind
  \      : a:default_kind
endfunction

function! s:list_key_bindings(key_table) abort
  " actions => {
  "   'keys': [[key_value, key_repr], ...],
  "   'label': label
  " }
  let actions = {}
  for [key, action] in items(a:key_table)
    if !has_key(actions, action)
      let actions[action] = {'keys': []}
    endif
    call add(actions[action].keys, [key, strtrans(key)])
  endfor
  for _ in values(actions)
    call sort(_.keys)
    let _.label = join(map(copy(_.keys), 'v:val[1]'), ' ')
  endfor
  silent! unlet _

  " key  action
  " ---  ------
  "  ^H  left  
  " -----------
  "   cell
  let action_names = sort(keys(actions), 's:compare_ignorecase')
  let max_action_name_width = max(map(keys(actions), 'len(v:val)'))
  let max_label_width = max(map(values(actions), 'len(v:val.label)'))
  let max_cell_width = max_action_name_width + 1 + max_label_width
  let spacer = '   '
  let columns = (&columns + len(spacer) - 1) / (max_cell_width + len(spacer))
  let columns = max([columns, 1])
  let n = len(actions)
  let rows = n / columns + (n % columns != 0)

  for row in range(rows)
    for column in range(columns)
      let i = column * rows + row
      if !(i < n)
        continue
      endif

      echon column == 0 ? "\n" : spacer

      echohl luisChooseAction
      let _ = action_names[i]
      echon _
      echohl NONE
      echon repeat(' ', max_action_name_width - len(_))

      echohl luisChooseKey
      echon ' '
      let _ = actions[action_names[i]].label
      echon _
      echohl NONE
      echon repeat(' ', max_label_width - len(_))
    endfor
  endfor
endfunction

function! s:make_skip_regexp(s) abort
  " 'abc' ==> '\Va*b*c'
  " '\!/' ==> '\V\\*!*/'
  " Here '*' means '\.\{-}'
  let [init, last] = [a:s[:-2], a:s[-1:]]
  return '\V'
  \    . substitute(escape(init, '\'), '\%(\\\\\|[^\\]\)\zs', '\\.\\{-}', 'g')
  \    . escape(last, '\')
endfunction
