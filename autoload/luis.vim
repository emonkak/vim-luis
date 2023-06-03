if !exists('g:luis#default_comparer')
  let g:luis#default_comparer = luis#comparer#default#import()
endif

if !exists('g:luis#default_matcher')
  let g:luis#default_matcher = exists('*matchfuzzypos')
  \                          ? luis#matcher#fuzzy_native#import()
  \                          : luis#matcher#fuzzy#import()
endif

if !exists('g:luis#default_previewer')
  let g:luis#default_previewer = has('nvim')
  \                          ? luis#previewer#floats#new()
  \                          : luis#previewer#popup#new()
endif

let s:SCHEMA_SELECTOR = {
\   'type': 'struct',
\   'properties': {
\     'is_active': {
\       'type': v:t_func,
\     },
\     'normalize_candidate': {
\       'type': v:t_func,
\       'optional': 1,
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
\   'properties': {
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
\   'properties': {
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

let s:SCHEMA_HOOK = {
\   'type': 'struct',
\   'properties': {
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
\   },
\ }

let s:SCHEMA_PREVIEWER = {
\   'type': 'struct',
\   'properties': {
\     'close': {
\       'type': v:t_func,
\     },
\     'is_active': {
\       'type': v:t_func,
\     },
\     'is_available': {
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

" Save the last started session to make possible restart.
let s:last_session = {}

function! luis#acc_text(pattern, candidates, source) abort
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

function! luis#detect_filetype(path, lines) abort
  if has('nvim')
    let _ =<< trim END
    vim.filetype.match({
      filename = vim.api.nvim_eval('a:path'),
      contents = vim.api.nvim_eval('a:lines'),
    }) or ''
END
    return luaeval(join(_, ''))
  else
    let temp_win = popup_create(a:lines, { 'hidden': 1 })
    let temp_bufnr = winbufnr(temp_win)
    try
      let command = 'doautocmd filetypedetect BufNewFile '
      \           . fnameescape(a:path)
      call win_execute(temp_win, command)
      return getbufvar(temp_bufnr, '&filetype')
    finally
      call popup_close(temp_win)
    endtry
  endif
endfunction

function! luis#do_action(action_name, candidate, context) abort
  let Action = s:find_action(a:context.kind, a:action_name)
  if Action is 0
    return 'No such action: ' . string(a:action_name)
  endif
  return Action(a:candidate, a:context)
endfunction

function! luis#restart() abort
  if empty(s:last_session) || !s:session.finder.is_active()
    echohl ErrorMsg
    echo 'luis: Not started yet'
    echohl NONE
    return 0
  endif

  return s:last_session.start()
endfunction

function! luis#start(finder, source, ...) abort
  let options = get(a:000, 0, {})
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

  if !luis#validate_finder(a:finder)
  \  || !luis#validate_source(a:source)
  \  || !luis#validate_matcher(matcher)
  \  || !luis#validate_comparer(comparer)
  \  || !luis#validate_previewer(previewer)
  \  || !luis#validate_hook(hook)
    return 0
  endif

  let session = luis#session#new(
  \    a:finder,
  \    a:source,
  \    matcher,
  \    comparer,
  \    previewer,
  \    hook,
  \ )

  if !session.start()
    return 0
  endif

  let s:last_session = session

  return 1
endfunction

function! luis#validate_comparer(comparer) abort
  return s:do_validate(s:SCHEMA_COMPARER, a:comparer, 'Comparer')
endfunction

function! luis#validate_finder(finder) abort
  return s:do_validate(s:SCHEMA_SELECTOR, a:finder, 'Finder')
endfunction

function! luis#validate_hook(hook) abort
  return s:do_validate(s:SCHEMA_HOOK, a:hook, 'Finder')
endfunction

function! luis#validate_kind(kind) abort
  if !s:do_validate(s:SCHEMA_KIND, a:kind, 'Kind')
    return 0
  endif

  let missing_action_names = filter(
  \   values(a:kind.key_table),
  \   's:find_action(a:kind, v:val) is 0'
  \ )
  if !empty(missing_action_names)
    echoerr 'luis: Missing actions are found:'
    \       join(missing_action_names, ', ')
    return 0
  endif

  return 1
endfunction

function! luis#validate_matcher(matcher) abort
  return s:do_validate(s:SCHEMA_MATCHER, a:matcher, 'Matcher')
endfunction

function! luis#validate_previewer(previewer) abort
  return s:do_validate(s:SCHEMA_PREVIEWER, a:previewer, 'Preview')
endfunction

function! luis#validate_source(source) abort
  return s:do_validate(s:SCHEMA_SOURCE, a:source, 'Source')
endfunction

function! s:do_validate(schema, value, name) abort
  let errors = luis#schema#validate(a:schema, a:value)
  if !empty(errors)
    echoerr 'luis: Invalid ' . a:name . ': ' . join(errors, ', ')
    return 0
  endif
  return 1
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

function! s:make_skip_regexp(s) abort
  " 'abc' ==> '\Va*b*c'
  " '\!/' ==> '\V\\*!*/'
  " Here '*' means '\.\{-}'
  let [init, last] = [a:s[:-2], a:s[-1:]]
  return '\V'
  \    . substitute(escape(init, '\'), '\%(\\\\\|[^\\]\)\zs', '\\.\\{-}', 'g')
  \    . escape(last, '\')
endfunction
