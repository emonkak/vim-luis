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
\     'format_candidate': {
\       'type': v:t_func,
\       'optional': 1,
\     },
\     'format_preview_content': {
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

let s:SCHEMA_SESSION = {
\   'type': 'struct',
\   'properties': {
\     'hook': s:SCHEMA_HOOK,
\     'is_active': {
\       'type': v:t_func,
\     },
\     'quit': {
\       'type': v:t_func,
\     },
\     'reload_candidates': {
\       'type': v:t_func,
\     },
\     'source': s:SCHEMA_SOURCE,
\     'start': {
\       'type': v:t_func,
\     },
\   },
\ }

let s:SCHEMA_PREVIEW_WINDOW = {
\   'type': 'struct',
\   'properties': {
\     'quit_preview': {
\       'type': v:t_func,
\     },
\     'is_active': {
\       'type': v:t_func,
\     },
\     'preview_buffer': {
\       'type': v:t_func,
\     },
\     'preview_lines': {
\       'type': v:t_func,
\     },
\   },
\ }

function! luis#validations#validate_kind(kind) abort
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

function! luis#validations#validate_matcher(matcher) abort
  return s:do_validate(s:SCHEMA_MATCHER, a:matcher, 'Matcher')
endfunction

function! luis#validations#validate_session(session) abort
  return s:do_validate(s:SCHEMA_SESSION, a:session, 'Session')
endfunction

function! luis#validations#validate_source(source) abort
  return s:do_validate(s:SCHEMA_SOURCE, a:source, 'Source')
endfunction

function! luis#validations#validate_preview_window(window) abort
  return s:do_validate(s:SCHEMA_PREVIEW_WINDOW, a:window, 'Preview')
endfunction

function! s:do_validate(schema, value, name) abort
  let errors = luis#schema#validate(a:schema, a:value)
  if !empty(errors)
    echoerr 'luis: Invalid ' . a:name . ': ' . join(errors, ', ')
  else
    return 1
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
