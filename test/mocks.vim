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

function! CreateMockPreviewWindow(is_active) abort
  return {
  \   'is_active': { -> a:is_active },
  \   'open_buffer': { bufnr, dimensions, options -> 0 },
  \   'open_text': { lines, dimensions, options -> 0 },
  \   'close': { -> 0 },
  \ }
endfunction

function! CreateMockSession(source, hook, candidate, is_active) abort
  return {
  \   'guess_candidate': { -> a:candidate },
  \   'hook': a:hook,
  \   'is_active': { -> a:is_active },
  \   'normalize_candidate': { candidate, index, context -> candidate },
  \   'quit': { -> 0 },
  \   'refresh_candidates': { -> 0 },
  \   'source': a:source,
  \   'start': { -> 0 },
  \ }
endfunction

function! CreateMockSource(...) abort
  let options = get(a:000, 0, {})
  let candidates = get(options, 'candidates', [])
  let source = {
  \   'gather_candidates': { context -> candidates },
  \   'is_valid_for_acc': { candidate -> get(candidate, 'is_valid_for_acc', 1) },
  \   'name': 'mock_source',
  \   'on_action': { candidate, context -> 0 },
  \   'on_preview': { candidate, context -> 0 },
  \   'on_source_enter': { context -> 0 },
  \   'on_source_leave': { context -> 0 },
  \ }
  let source.default_kind = has_key(options, 'default_kind')
  \                       ? options.default_kind
  \                       : CreateMockKind()
  if has_key(options, 'comparer')
    let source.comparer = options.comparer
  endif
  if has_key(options, 'matcher')
    let source.matcher = options.matcher
  endif
  return source
endfunction

function! CreateMockComp(...) abort
  let options = get(a:000, 0, {})
  let candidates = get(options, 'candidates', [])
  let source = {
  \   'gather_candidates': { context -> candidates },
  \   'is_valid_for_acc': { candidate -> get(candidate, 'is_valid_for_acc', 1) },
  \   'name': 'mock_source',
  \   'on_action': { candidate, context -> 0 },
  \   'on_preview': { candidate, context -> 0 },
  \   'on_source_enter': { context -> 0 },
  \   'on_source_leave': { context -> 0 },
  \ }
  let source.default_kind = has_key(options, 'default_kind')
  \                       ? options.default_kind
  \                       : CreateMockKind()
  if has_key(options, 'comparer')
    let source.comparer = options.comparer
  endif
  if has_key(options, 'matcher')
    let source.matcher = options.matcher
  endif
  return source
endfunction

function! CreateMockComparer() abort
  return {
  \   'compare_candidates': { first, second ->
  \     first.word < second.word ? -1 : first.word > second.word ? 1 : 0
  \   },
  \   'normalize_candidate': { candidate, index, context -> candidate },
  \ }
endfunction
