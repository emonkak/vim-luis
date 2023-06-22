function! CreateMockComparer() abort
  return {
  \   'compare_candidates': { first, second ->
  \     first.word < second.word ? -1 : first.word > second.word ? 1 : 0
  \   },
  \   'normalize_candidate': { candidate, index, context -> candidate },
  \ }
endfunction

function! CreateMockUI(...) abort
  let overrides = get(a:000, 0, {})
  return {
  \   'current_pattern': { -> get(overrides, 'pattern', '') },
  \   'guess_candidate': { -> get(overrides, 'candidate', 0) },
  \   'preview_bounds': { -> get(overrides, 'preview_bounds', {
  \     'row': 0,
  \     'col': 0,
  \     'width': 0,
  \     'height': 0,
  \   })},
  \   'is_active': { -> get(overrides, 'is_active', 0) },
  \   'normalize_candidate': { candidate, index, context -> candidate },
  \   'quit': { -> 0 },
  \   'refresh_candidates': { -> 0 },
  \   'start': { -> 0 },
  \ }
endfunction

function! CreateMockHook() abort
  return {
  \   'normalize_candidate': { candidate, index, context -> candidate },
  \   'on_action': { candidate, context -> 0 },
  \   'on_preview': { candidate, context -> 0 },
  \   'on_source_enter': { context -> 0 },
  \   'on_source_leave': { context -> 0 },
  \ }
endfunction

function! CreateMockKind() abort
  return {
  \   'name': 'mock_kind',
  \   'action_table': {
  \     'default': { candidate, context -> 0 },
  \   },
  \   'key_table': {
  \     "\<CR>": 'default',
  \   },
  \ }
endfunction

function! CreateMockMatcher() abort
  return {
  \   'filter_candidates': { candidates, context -> candidates },
  \   'normalize_candidate': { candidate, index, context -> candidate },
  \   'sort_candidates': { candidates, context -> candidates },
  \ }
endfunction

function! CreateMockPreviewer(...) abort
  let overrides = get(a:000, 0, {})
  return {
  \   'is_active': { -> get(overrides, 'is_active', 0) },
  \   'open_buffer': { bufnr, bounds, options -> 0 },
  \   'open_text': { lines, bounds, options -> 0 },
  \   'close': { -> 0 },
  \ }
endfunction

function! CreateMockSource(...) abort
  let overrides = get(a:000, 0, {})
  let source = {
  \   'gather_candidates': { context -> get(overrides, 'candidates', []) },
  \   'name': 'mock_source',
  \   'on_action': { candidate, context -> 0 },
  \   'on_preview': { candidate, context -> 0 },
  \   'on_source_enter': { context -> 0 },
  \   'on_source_leave': { context -> 0 },
  \ }
  let source.default_kind = has_key(overrides, 'default_kind')
  \                       ? overrides.default_kind
  \                       : CreateMockKind()
  if has_key(overrides, 'comparer')
    let source.comparer = overrides.comparer
  endif
  if has_key(overrides, 'matcher')
    let source.matcher = overrides.matcher
  endif
  if has_key(overrides, 'is_valid_for_acc')
    let source.is_valid_for_acc = overrides.is_valid_for_acc
  endif
  return source
endfunction
