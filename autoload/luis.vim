if !exists('s:session')
  let s:session = {}
endif

function! luis#do_action(kind, action_name, candidate) abort
  let Action = s:find_action(a:kind, a:action_name)
  if Action is 0
    return 'luis: Action ' . string(a:action_name) . ' not defined'
  endif
  let context = { 'kind': a:kind, 'session': s:session }
  return Action(a:candidate, context)
endfunction

function! luis#quit() abort
  if empty(s:session) || !s:session.is_active()
    echohl ErrorMsg
    echo 'luis: Session not active'
    echohl NONE
    return 0
  endif

  call s:quit_session(s:session)

  return 1
endfunction

function! luis#restart() abort
  if empty(s:session)
    echohl ErrorMsg
    echo 'luis: Session not started yet'
    echohl NONE
    return 0
  endif

  if s:session.is_active()
    echohl ErrorMsg
    echo 'luis: Session already active'
    echohl NONE
    return 0
  endif

  call s:start_session(s:session)

  return 1
endfunction

function! luis#start(new_session) abort
  if !empty(s:session) && s:session.is_active()
    echohl ErrorMsg
    echo 'luis: Session already active'
    echohl NONE
    return 0
  endif

  if !luis#validations#validate_session(a:new_session)
    return 0
  endif

  call s:start_session(a:new_session)

  let s:session = a:new_session

  return 1
endfunction

function! luis#take_action(...) abort
  if empty(s:session) || !s:session.is_active()
    echohl ErrorMsg
    echo 'luis: Session not active'
    echohl NONE
    return 0
  endif

  let candidate = s:session.guess_candidate()
  let kind = s:kind_from_candidate(candidate, s:session.source.default_kind)
  let action_name = a:0 > 0 ? a:1 : s:choose_action(kind, candidate)

  if action_name isnot 0
    let context = {
    \   'kind': kind,
    \   'session': s:session,
    \ }

    if has_key(s:session.source, 'on_action')
      call s:session.source.on_action(candidate, context)
    endif

    if has_key(s:session.hook, 'on_action')
      call s:session.hook.on_action(candidate, context)
    endif
  endif

  " Close the luis window, because some kind of actions does something on the
  " current buffer/window and user expects that such actions do something on
  " the buffer/window which was the current one until the luis buffer became
  " active.
  call s:quit_session(s:session)

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

function! luis#_clear_session() abort
  " For test-only
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
  for [key, action_name] in items(a:key_table)
    if !has_key(actions, action_name)
      let actions[action_name] = { 'keys': [] }
    endif
    call add(actions[action_name].keys, [key, strtrans(key)])
  endfor
  for action in values(actions)
    call sort(action.keys)
    let action.label = join(map(copy(action.keys), 'v:val[1]'), ' ')
  endfor

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

function! s:quit_session(session) abort
  let context = { 'session': a:session }

  if has_key(a:session.source, 'on_source_leave')
    call a:session.source.on_source_leave(context)
  endif

  if has_key(a:session.hook, 'on_source_leave')
    call a:session.hook.on_source_leave(context)
  endif

  call a:session.quit()
endfunction

function! s:start_session(session) abort
  call a:session.start()

  let context = { 'session': a:session }

  if has_key(a:session.hook, 'on_source_enter')
    call a:session.hook.on_source_enter(context)
  endif

  if has_key(a:session.source, 'on_source_enter')
    call a:session.source.on_source_enter(context)
  endif
endfunction
