silent doautocmd <nomodeline> User LuisInit

if !exists('g:luis#default_comparer')
  let g:luis#default_comparer = luis#comparer#default#import()
endif

if !exists('g:luis#default_matcher')
  let g:luis#default_matcher = exists('*matchfuzzypos')
  \                          ? luis#matcher#fuzzy_native#import()
  \                          : luis#matcher#fuzzy#import()
endif

if !exists('g:luis#default_previewer')
  let g:luis#default_previewer = exists('*popup_create')
  \                            ? luis#previewer#popup#new()
  \                            : exists('*nvim_open_win')
  \                            ? luis#previewer#float#new()
  \                            : luis#previewer#null#import()
endif

if !exists('g:luis#default_ui')
  let g:luis#default_ui = luis#ui#popupmenu#new()
endif

if !exists('s:session_id')
  let s:session_id = 1
endif

let s:SCHEMA_UI = {
\   'type': 'struct',
\   'attributes': {
\     'current_pattern': {
\       'type': v:t_func,
\     },
\     'guess_candidate': {
\       'type': v:t_func,
\     },
\     'is_active': {
\       'type': v:t_func,
\     },
\     'normalize_candidate': {
\       'type': v:t_func,
\       'optional': 1,
\     },
\     'preview_bounds': {
\       'type': v:t_func,
\     },
\     'quit': {
\       'type': v:t_func,
\     },
\     'refresh_candidates': {
\       'type': v:t_func,
\     },
\     'start': {
\       'type': v:t_func,
\     },
\   },
\ }

let s:SCHEMA_KIND = {
\   'type': 'struct',
\   'attributes': {
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

let s:SCHEMA_KIND.attributes.prototype = {
\   'type': 'struct',
\   'attributes': s:SCHEMA_KIND.attributes,
\   'optional': 1,
\ }

let s:SCHEMA_MATCHER = {
\   'type': 'struct',
\   'attributes': {
\     'filter_candidates': {
\       'type': v:t_func,
\     },
\     'normalize_candidate': {
\       'type': v:t_func,
\       'optional': 1,
\     },
\     'sort_candidates': {
\       'type': v:t_func,
\     },
\   },
\ }

let s:SCHEMA_COMPARER = {
\   'type': 'struct',
\   'attributes': {
\     'compare_candidates': {
\       'type': v:t_func,
\     },
\     'normalize_candidate': {
\       'type': v:t_func,
\       'optional': 1,
\     },
\   },
\ }

let s:SCHEMA_SOURCE = {
\   'type': 'struct',
\   'attributes': {
\     'name': {
\       'type': v:t_string,
\     },
\     'comparer': extend({ 'optional': 1 }, s:SCHEMA_COMPARER, 'keep'),
\     'default_kind': s:SCHEMA_KIND,
\     'matcher': extend({ 'optional': 1 }, s:SCHEMA_MATCHER, 'keep'),
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
\     'is_component_separator': {
\       'type': v:t_func,
\       'optional': 1,
\     },
\     'is_valid_for_acc': {
\       'type': v:t_func,
\       'optional': 1,
\     },
\   },
\ }

let s:SCHEMA_HOOK = {
\   'type': 'struct',
\   'attributes': {
\     'normalize_candidate': {
\       'type': v:t_func,
\       'optional': 1,
\     },
\     'on_action': {
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
\     'on_preview': {
\       'type': v:t_func,
\       'optional': 1,
\     },
\   },
\ }

let s:SCHEMA_PREVIEWER = {
\   'type': 'struct',
\   'attributes': {
\     'close': {
\       'type': v:t_func,
\     },
\     'is_active': {
\       'type': v:t_func,
\     },
\     'open_buffer': {
\       'type': v:t_func,
\     },
\     'open_text': {
\       'type': v:t_func,
\     },
\   },
\ }

function! luis#acc_text(pattern, candidates, source) abort
  " ACC = Automatic Component Completion
  let sep = a:pattern[-1:]
  let components = split(a:pattern, sep, 1)

  if len(components) < 2
    throw 'luis: Assumption on ACC is failed: ' . string(components)
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

function! luis#collect_candidates(session, pattern) abort
  let context = { 'pattern': a:pattern, 'session': a:session }
  let normalizers = []

  if has_key(a:session.comparer, 'normalize_candidate')
    call add(normalizers, a:session.comparer)
  endif
  if has_key(a:session.matcher, 'normalize_candidate')
    call add(normalizers, a:session.matcher)
  endif
  if has_key(a:session.hook, 'normalize_candidate')
    call add(normalizers, a:session.hook)
  endif
  if has_key(a:session.ui, 'normalize_candidate')
    call add(normalizers, a:session.ui)
  endif

  let candidates = a:session.source.gather_candidates(context)
  let candidates = a:session.matcher.filter_candidates(candidates, context)
  for i in range(len(candidates))
    " Action expects 'user_data' to be defined, so we will complete it.
    if !has_key(candidates[i], 'user_data')
      let candidates[i].user_data = {}
    endif
    for normalizer in normalizers
      let candidates[i] = normalizer.normalize_candidate(
      \   candidates[i],
      \   i,
      \   context
      \ )
    endfor
  endfor
  let candidates = a:session.matcher.sort_candidates(candidates, context)

  return candidates
endfunction

function! luis#do_action(session, action_name, candidate) abort
  let kind = get(a:candidate.user_data, 'kind', a:session.source.default_kind)
  let Action = s:find_action(kind, a:action_name)

  if Action is 0
    throw 'luis: No such action: ' . string(a:action_name)
  endif

  let context = {
  \   'action': Action,
  \   'action_name': a:action_name,
  \   'kind': kind,
  \   'session': a:session,
  \ }

  if has_key(a:session.source, 'on_action')
    call a:session.source.on_action(a:candidate, context)
  endif

  if has_key(a:session.hook, 'on_action')
    call a:session.hook.on_action(a:candidate, context)
  endif

  " The action may have been modified by a callback.
  let Action = context.action

  call Action(a:candidate, context)
endfunction

function! luis#new_session(source, ...) abort
  let options = get(a:000, 0, {})
  let ui = get(options, 'ui', g:luis#default_ui)
  let matcher = get(
  \   options,
  \   'matcher',
  \   get(a:source, 'matcher', g:luis#default_matcher)
  \ )
  let comparer = get(
  \   options,
  \   'comparer',
  \   get(a:source, 'comparer', g:luis#default_comparer)
  \ )
  let previewer = get(options, 'previewer', g:luis#default_previewer)
  let hook = get(options, 'hook', {})
  let initial_pattern = get(options, 'initial_pattern', '')

  call luis#_validate_source(a:source)
  call luis#_validate_ui(ui)
  call luis#_validate_matcher(matcher)
  call luis#_validate_comparer(comparer)
  call luis#_validate_previewer(previewer)
  call luis#_validate_hook(hook)

  let session = {
  \   'id': s:session_id,
  \   'source': a:source,
  \   'ui': ui,
  \   'matcher': matcher,
  \   'comparer': comparer,
  \   'previewer': previewer,
  \   'hook': hook,
  \   'initial_pattern': initial_pattern,
  \ }

  let s:session_id += 1

  return session
endfunction

function! luis#preview_candidate(session) abort
  let candidate = a:session.ui.guess_candidate()

  if candidate is 0
    return 0
  endif

  let previewer = a:session.previewer
  let context = { 'session': a:session }

  if has_key(a:session.source, 'on_preview')
    call a:session.source.on_preview(candidate, context)
  endif

  if has_key(a:session.hook, 'on_preview')
    call a:session.hook.on_preview(candidate, context)
  endif

  if has_key(candidate.user_data, 'preview_function')
    let lines = candidate.user_data.preview_function(candidate)
    let hints = s:preview_hints_from_candidate(candidate)
    let bounds = a:session.ui.preview_bounds()
    call previewer.open_text(lines, bounds, hints)
    return 1
  endif

  if has_key(candidate.user_data, 'preview_lines')
    let hints = s:preview_hints_from_candidate(candidate)
    let bounds = a:session.ui.preview_bounds()
    call previewer.open_text(
    \   candidate.user_data.preview_lines,
    \   bounds,
    \   hints
    \ )
    return 1
  endif

  if has_key(candidate.user_data, 'preview_bufnr')
    let bufnr = candidate.user_data.preview_bufnr
    if bufexists(bufnr)
      let bounds = a:session.ui.preview_bounds()
      let hints = s:preview_hints_from_candidate(candidate)
      call previewer.open_buffer(
      \   bufnr,
      \   bounds,
      \   hints
      \ )
      return 1
    endif
  endif

  if has_key(candidate.user_data, 'preview_path')
    let path = candidate.user_data.preview_path
    if filereadable(path)
      try
        let bounds = a:session.ui.preview_bounds()
        " Read one extra line to avoid syntax errors. e.g., JSON trailing
        " comma.
        let lines = readfile(path, '', bounds.height + 1)
        let hints = s:preview_hints_from_candidate(candidate)
        call previewer.open_text(
        \   lines,
        \   bounds,
        \   hints
        \ )
        return 1
      catch /\<E\(484\|485\):/
        " Ignore an error for file reading.
      endtry
    endif
  endif

  call previewer.close()

  return 0
endfunction

function! luis#quit(session) abort
  if !a:session.ui.is_active()
    echohl ErrorMsg
    echomsg 'luis: Not active'
    echohl NONE
    return 0
  endif

  call s:quit_session(a:session)

  return 1
endfunction

function! luis#start(session) abort
  if a:session.ui.is_active()
    echohl ErrorMsg
    echomsg 'luis: Already active'
    echohl NONE
    return 0
  endif

  call s:start_session(a:session)

  return 1
endfunction

function! luis#take_action(session, action_name) abort
  let candidate = a:session.ui.guess_candidate()

  if candidate is 0
    " Make a ad-hoc candidate based on the current pattern.
    let current_pattern = a:session.ui.current_pattern()
    let candidate = {
    \   'word': current_pattern,
    \   'user_data': {},
    \ }
  endif

  " Close the UI window, because some kind of actions does something on the
  " current buffer/window and user expects that such actions do something on
  " the buffer/window which was the current one until the UI buffer became
  " active.
  call s:quit_session(a:session)

  if a:action_name == '*'
    let kind = get(candidate.user_data, 'kind', a:session.source.default_kind)
    let action_name = s:choose_action(kind, candidate)
  else
    let action_name = a:action_name
  endif

  if action_name == ''
    return 0
  endif

  try
    call luis#do_action(a:session, action_name, candidate)
    return 1
  catch
    echohl ErrorMsg
    echomsg v:exception
    echohl NONE
    return 0
  endtry
endfunction

function! luis#_validate_comparer(comparer) abort
  call s:do_validate(s:SCHEMA_COMPARER, a:comparer, 'Comparer')
endfunction

function! luis#_validate_hook(hook) abort
  call s:do_validate(s:SCHEMA_HOOK, a:hook, 'UI')
endfunction

function! luis#_validate_kind(kind) abort
  call s:do_validate(s:SCHEMA_KIND, a:kind, 'Kind')

  let missing_action_names = filter(
  \   values(a:kind.key_table),
  \   's:find_action(a:kind, v:val) is 0'
  \ )
  if !empty(missing_action_names)
    throw 'luis: Missing actions are found:'
    \       join(missing_action_names, ', ')
  endif
endfunction

function! luis#_validate_matcher(matcher) abort
  call s:do_validate(s:SCHEMA_MATCHER, a:matcher, 'Matcher')
endfunction

function! luis#_validate_previewer(previewer) abort
  call s:do_validate(s:SCHEMA_PREVIEWER, a:previewer, 'Preview')
endfunction

function! luis#_validate_source(source) abort
  call s:do_validate(s:SCHEMA_SOURCE, a:source, 'Source')
endfunction

function! luis#_validate_ui(ui) abort
  call s:do_validate(s:SCHEMA_UI, a:ui, 'UI')
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
  redrawstatus  " clear the menu message lines to avoid hit-enter prompt.

  " Return the action bound to the key k.
  if has_key(key_table, k)
    return key_table[k]
  else
    echo 'The key' string(k) 'is not associated with any action'
    \    '-- nothing happened.'
    return ''
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

function! s:do_validate(schema, value, name) abort
  let errors = luis#schema#validate(a:schema, a:value)
  if !empty(errors)
    throw 'luis: Invalid ' . a:name . ': ' . join(errors, ', ')
  endif
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
      let action_name = action_names[i]
      echon action_name
      echohl NONE
      echon repeat(' ', max_action_name_width - len(action_name))

      echohl luisChooseKey
      echon ' '
      let action = actions[action_name]
      echon action.label
      echohl NONE
      echon repeat(' ', max_label_width - len(action.label))
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

function! s:preview_hints_from_candidate(candidate) abort
  let hints = {}

  if has_key(a:candidate.user_data, 'preview_bufnr')
    let hints.bufnr = a:candidate.user_data.preview_bufnr
  endif

  if has_key(a:candidate.user_data, 'preview_cursor')
    let hints.cursor = a:candidate.user_data.preview_cursor
  endif

  if has_key(a:candidate.user_data, 'preview_filetype')
    let hints.filetype = a:candidate.user_data.preview_filetype
  endif

  if has_key(a:candidate.user_data, 'preview_path')
    let hints.path = a:candidate.user_data.preview_path
  endif

  if has_key(a:candidate.user_data, 'preview_title')
    let hints.title = a:candidate.user_data.preview_title
  elseif has_key(hints, 'bufnr')
    let title = bufname(hints.bufnr)
    let title = title != '' ? fnamemodify(title, ':t') : '[No Name]'
    if has_key(hints, 'cursor')
      let [lnum, col] = hints.cursor
      let title .= ':' . lnum . ':' . col
    endif
    let hints.title = title
  elseif has_key(hints, 'path')
    let title = fnamemodify(hints.path, ':t')
    if has_key(hints, 'cursor')
      let [lnum, col] = hints.cursor
      let title .= ':' . lnum . ':' . col
    endif
    let hints.title = title
  endif

  return hints
endfunction

function! s:quit_session(session) abort
  let context = { 'session': a:session }

  if has_key(a:session.source, 'on_source_leave')
    call a:session.source.on_source_leave(context)
  endif

  if has_key(a:session.hook, 'on_source_leave')
    call a:session.hook.on_source_leave(context)
  endif

  if a:session.previewer.is_active()
    call a:session.previewer.close()
  endif

  call a:session.ui.quit()
endfunction

function! s:start_session(session) abort
  call a:session.ui.start(a:session)

  let context = { 'session': a:session }

  if has_key(a:session.hook, 'on_source_enter')
    call a:session.hook.on_source_enter(context)
  endif

  if has_key(a:session.source, 'on_source_enter')
    call a:session.source.on_source_enter(context)
  endif
endfunction
