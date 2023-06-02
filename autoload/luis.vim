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

function! luis#do_action(action_name, candidate, context) abort
  let Action = s:find_action(a:context.kind, a:action_name)
  if Action is 0
    return 'There is no such action: ' . string(a:action_name)
  endif
  return Action(a:candidate, a:context)
endfunction

function! luis#restart() abort
  if empty(s:last_session)
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

  call session.start()

  let s:last_session = session

  return 1
endfunction

function! luis#validate_comparer(comparer) abort
  return s:do_validate(s:SCHEMA_COMPARER, a:comparer, 'Comparer')
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

function! luis#validate_finder(finder) abort
  return s:do_validate(s:SCHEMA_SELECTOR, a:finder, 'Finder')
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
