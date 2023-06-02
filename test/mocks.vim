function! CreateMockComparer() abort
  return {
  \   'compare_candidates': { first, second ->
  \     first.word < second.word ? -1 : first.word > second.word ? 1 : 0
  \   },
  \   'normalize_candidate': { candidate, index, context -> candidate },
  \ }
endfunction

function! CreateMockFinder(candidate, is_active) abort
  return {
  \   'guess_candidate': { -> a:candidate },
  \   'is_active': { -> a:is_active },
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

function! CreateMockPreviewer(is_available, is_active) abort
  return {
  \   'is_available': { -> a:is_available },
  \   'is_active': { -> a:is_active },
  \   'open_buffer': { bufnr, bounds, options -> 0 },
  \   'open_text': { lines, bounds, options -> 0 },
  \   'close': { -> 0 },
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
