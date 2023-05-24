function! CreateMockHook() abort
  return {
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
  \   'preview_buffer': { bufnr, dimensions, options -> 0 },
  \   'preview_text': { lines, dimensions, options -> 0 },
  \   'quit_preview': { -> 0 },
  \ }
endfunction

function! CreateMockSession(source, candidate, is_active) abort
  return {
  \   'source': a:source,
  \   'guess_candidate': { -> a:candidate },
  \   'is_active': { -> a:is_active },
  \   'quit': { -> 0 },
  \   'reload_candidates': { -> 0 },
  \   'start': { -> 0 },
  \ }
endfunction

function! CreateMockSource(default_kind, matcher, candidates) abort
  let source = {
  \   'default_kind': a:default_kind,
  \   'gather_candidates': { context -> a:candidates },
  \   'is_valid_for_acc': { candidate -> get(candidate, 'is_valid_for_acc', 1) },
  \   'matcher': a:matcher,
  \   'name': 'mock_source',
  \   'on_action': { candidate, context -> 0 },
  \   'on_source_enter': { context -> 0 },
  \   'on_source_leave': { context -> 0 },
  \ }
  if a:matcher isnot 0
    let source.matcher = a:matcher
  endif
  return source
endfunction
