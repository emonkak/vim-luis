silent runtime! test/spy.vim
silent runtime! test/mocks.vim

function! s:test_acc_text() abort
  let source = CreateMockSource()

  let cs1 = [
  \   { 'word': 'usr/share/man/man1' },
  \ ]
  let cs2 = [
  \   { 'word': 'usr/share/w y 1' },
  \   { 'word': 'usr/share/ x z2' },
  \   { 'word': 'usr/share/w y 3' },
  \   { 'word': 'usr/share/ x z4' },
  \ ]
  let cs3 = [
  \   { 'word': 'bin/1/1' },
  \   { 'word': 'etc/2/2' },
  \   { 'word': 'usr/3/3' },
  \   { 'word': 'var/4/4' },
  \ ]
  let cs4 = [
  \   { 'word': '1/X', 'is_valid_for_acc': 0 },
  \   { 'word': '2/X', 'is_valid_for_acc': 0 },
  \   { 'word': '3/X' },
  \   { 'word': '4/X', 'is_valid_for_acc': 0 },
  \ ]

  " len(components) == 2
  call assert_equal('usr', luis#acc_text('/', cs1, source))
  call assert_equal('usr', luis#acc_text('u/', cs1, source))
  call assert_equal('usr', luis#acc_text('s/', cs1, source))
  call assert_equal('usr/share', luis#acc_text('sh/', cs1, source))
  call assert_equal('usr/share/man', luis#acc_text('m/', cs1, source))
  call assert_equal('usr/share/man/man1', luis#acc_text('1/', cs1, source))

  call assert_equal('usr/share/w y 1', luis#acc_text('w/', cs2, source))
  call assert_equal('usr/share/ x z2', luis#acc_text('x/', cs2, source))
  call assert_equal('usr/share/w y 1', luis#acc_text('y/', cs2, source))
  call assert_equal('usr/share/ x z2', luis#acc_text('z/', cs2, source))

  call assert_equal('bin', luis#acc_text('b/', cs3, source))
  call assert_equal('etc', luis#acc_text('e/', cs3, source))
  call assert_equal('usr', luis#acc_text('r/', cs3, source))
  call assert_equal('usr', luis#acc_text('u/', cs3, source))
  call assert_equal('var', luis#acc_text('v/', cs3, source))

  call assert_equal('3/X', luis#acc_text('X/', cs4, source))

  " len(components) >= 3
  call assert_equal('usr/share', luis#acc_text('usr//', cs1, source))
  call assert_equal('usr/share', luis#acc_text('usr/s/', cs1, source))
  call assert_equal('usr/share', luis#acc_text('usr/sh/', cs1, source))
  call assert_equal('usr/share/man', luis#acc_text('usr/m/', cs1, source))
  call assert_equal('usr/share/man/man1', luis#acc_text('usr/1/', cs1, source))
  call assert_equal('usr/share', luis#acc_text('usr/share/', cs1, source))

  call assert_equal('usr/share/man', luis#acc_text('usr/share//', cs1, source))
  call assert_equal('usr/share/man', luis#acc_text('usr/share/m/', cs1, source))
  call assert_equal('usr/share/man/man1', luis#acc_text('usr/share/1/', cs1, source))

  call assert_equal('etc/2', luis#acc_text('etc//', cs3, source))
  call assert_equal('var/4', luis#acc_text('var//', cs3, source))

  " No components
  let v:errmsg = ''
  silent! call luis#acc_text('', [], source)
  call assert_match('luis: Assumption on ACC is failed:', v:errmsg)

  let v:errmsg = ''
  silent! call assert_equal('', luis#acc_text('', cs1, source))
  call assert_match('luis: Assumption on ACC is failed:', v:errmsg)

  " No proper candidate for a:pattern
  call assert_equal('', luis#acc_text('x/', [], source))
  call assert_equal('', luis#acc_text('x/', cs1, source))
  call assert_equal('', luis#acc_text('2/', cs1, source))
  call assert_equal('', luis#acc_text('u/s/m/', cs1, source))
  call assert_equal('', luis#acc_text('USR//', cs1, source))
endfunction

function! s:test_collect_candidates__with_default_matcher_and_comparer() abort
  let candidates = [
  \   { 'word': 'foo' },
  \   { 'word': 'foobar' },
  \   { 'word': 'foobarbaz' },
  \ ]
  let [comparer, comparer_spies] = SpyDict(CreateMockComparer())
  let [matcher, matcher_spies] = SpyDict(CreateMockMatcher())
  let [source, source_spies] = SpyDict(CreateMockSource({
  \   'candidates': candidates,
  \ }))
  let [hook, hook_spies] = SpyDict(CreateMockHook())
  let [session, session_spies] = SpyDict(CreateMockSession(source, hook, {}, 1))

  let original_matcher = g:luis#default_matcher
  let original_comparer = g:luis#default_comparer
  let g:luis#default_matcher = matcher
  let g:luis#default_comparer = comparer

  try
    let pattern = 'foo'
    let expected_context = {
    \   'comparer': comparer,
    \   'pattern': pattern,
    \   'matcher': matcher,
    \   'session': session,
    \ }

    call assert_equal(
    \   candidates,
    \   luis#collect_candidates(session, pattern)
    \ )
    call assert_equal(1, source_spies.gather_candidates.call_count())
    call assert_equal(
    \   [expected_context],
    \   source_spies.gather_candidates.last_args()
    \ )
    call assert_equal(1, matcher_spies.filter_candidates.call_count())
    call assert_equal(
    \   [candidates, expected_context],
    \   matcher_spies.filter_candidates.last_args()
    \ )
    call assert_equal([
    \   [candidates[0], 0, expected_context],
    \   [candidates[1], 1, expected_context],
    \   [candidates[2], 2, expected_context],
    \ ], comparer_spies.normalize_candidate.args())
    call assert_equal([
    \   [candidates[0], 0, expected_context],
    \   [candidates[1], 1, expected_context],
    \   [candidates[2], 2, expected_context],
    \ ], matcher_spies.normalize_candidate.args())
    call assert_equal([
    \   [candidates[0], 0, expected_context],
    \   [candidates[1], 1, expected_context],
    \   [candidates[2], 2, expected_context],
    \ ], hook_spies.normalize_candidate.args())
    call assert_equal([
    \   [candidates[0], 0, expected_context],
    \   [candidates[1], 1, expected_context],
    \   [candidates[2], 2, expected_context],
    \ ], session_spies.normalize_candidate.args())
    call assert_equal(1, matcher_spies.sort_candidates.call_count())
    call assert_equal(
    \   [candidates, expected_context],
    \   matcher_spies.sort_candidates.last_args()
    \ )
  finally
    let g:luis#default_comparer = original_comparer
    let g:luis#default_matcher = original_matcher
  endtry
endfunction

function! s:test_collect_candidates__with_source_matcher_and_comparer() abort
  let candidates = [
  \   { 'word': 'foo' },
  \   { 'word': 'foobar' },
  \   { 'word': 'foobarbaz' },
  \ ]
  let [comparer, comparer_spies] = SpyDict(CreateMockComparer())
  let [default_matcher, default_matcher_spies] = SpyDict(CreateMockMatcher())
  let [source_matcher, source_matcher_spies] = SpyDict(CreateMockMatcher())
  let [source, source_spies] = SpyDict(CreateMockSource({
  \   'candidates': candidates,
  \   'matcher': source_matcher,
  \   'comparer': comparer,
  \ }))
  let [hook, hook_spies] = SpyDict(CreateMockHook())
  let [session, session_spies] = SpyDict(CreateMockSession(source, hook, {}, 1))

  let original_matcher = g:luis#default_matcher
  let g:luis#default_matcher = default_matcher

  try
    let pattern = 'foo'
    let expected_context = {
    \   'comparer': comparer,
    \   'pattern': pattern,
    \   'matcher': source_matcher,
    \   'session': session,
    \ }

    call assert_equal(
    \   candidates,
    \   luis#collect_candidates(session, pattern)
    \ )
    call assert_equal(1, source_spies.gather_candidates.call_count())
    call assert_equal(
    \   [expected_context],
    \   source_spies.gather_candidates.last_args()
    \ )
    call assert_equal(0, default_matcher_spies.filter_candidates.call_count())
    call assert_equal(1, source_matcher_spies.filter_candidates.call_count())
    call assert_equal(
    \   [candidates, expected_context],
    \   source_matcher_spies.filter_candidates.last_args()
    \ )
    call assert_equal(0, default_matcher_spies.normalize_candidate.call_count())
    call assert_equal([
    \   [candidates[0], 0, expected_context],
    \   [candidates[1], 1, expected_context],
    \   [candidates[2], 2, expected_context],
    \ ], comparer_spies.normalize_candidate.args())
    call assert_equal([
    \   [candidates[0], 0, expected_context],
    \   [candidates[1], 1, expected_context],
    \   [candidates[2], 2, expected_context],
    \ ], source_matcher_spies.normalize_candidate.args())
    call assert_equal([
    \   [candidates[0], 0, expected_context],
    \   [candidates[1], 1, expected_context],
    \   [candidates[2], 2, expected_context],
    \ ], hook_spies.normalize_candidate.args())
    call assert_equal([
    \   [candidates[0], 0, expected_context],
    \   [candidates[1], 1, expected_context],
    \   [candidates[2], 2, expected_context],
    \ ], session_spies.normalize_candidate.args())
    call assert_equal(0, default_matcher_spies.sort_candidates.call_count())
    call assert_equal(1, source_matcher_spies.sort_candidates.call_count())
    call assert_equal(
    \   [candidates, expected_context],
    \   source_matcher_spies.sort_candidates.last_args()
    \ )
  finally
    let g:luis#default_matcher = original_matcher
  endtry
endfunction

function! s:test_default_comparer() abort
  let comparer = g:luis#default_comparer

  call assert_equal(
  \   { 'word': 'A', 'luis_sort_priority': 0 },
  \   comparer.normalize_candidate({ 'word': 'A' }, 0, {})
  \ )
  call assert_equal(
  \   { 'word': 'A', 'luis_sort_priority': 1 },
  \   comparer.normalize_candidate(
  \     { 'word': 'A', 'luis_sort_priority': 1 },
  \     0,
  \     {}
  \   )
  \ )

  call assert_equal(
  \   0,
  \   comparer.compare_candidates(
  \     { 'word': 'A', 'luis_sort_priority': 0 },
  \     { 'word': 'A', 'luis_sort_priority': 0 }
  \   )
  \ )
  call assert_equal(
  \   -1,
  \   comparer.compare_candidates(
  \     { 'word': 'A', 'luis_sort_priority': 0 },
  \     { 'word': 'B', 'luis_sort_priority': 0 }
  \   )
  \ )
  call assert_equal(
  \   1,
  \   comparer.compare_candidates(
  \     { 'word': 'B', 'luis_sort_priority': 0 },
  \     { 'word': 'A', 'luis_sort_priority': 0 }
  \   )
  \ )
  call assert_equal(
  \   -1,
  \   comparer.compare_candidates(
  \     { 'word': 'A', 'luis_sort_priority': 1 },
  \     { 'word': 'A', 'luis_sort_priority': 0 }
  \   )
  \ )
  call assert_equal(
  \   -1,
  \   comparer.compare_candidates(
  \     { 'word': 'B', 'luis_sort_priority': 1 },
  \     { 'word': 'A', 'luis_sort_priority': 0 }
  \   )
  \ )
  call assert_equal(
  \   1,
  \   comparer.compare_candidates(
  \     { 'word': 'A', 'luis_sort_priority': 0 },
  \     { 'word': 'A', 'luis_sort_priority': 1 }
  \   )
  \ )
  call assert_equal(
  \   1,
  \   comparer.compare_candidates(
  \     { 'word': 'B', 'luis_sort_priority': 0 },
  \     { 'word': 'A', 'luis_sort_priority': 1 }
  \   )
  \ )
endfunction

function! s:test_detect_filetype() abort
  if !has('nvim') && !exists('*popup_create')
    return 'popup_create() function is required.'
  endif

  filetype on

  try
    call assert_equal('', luis#detect_filetype('foo', []))
    call assert_equal('c', luis#detect_filetype('foo.c', []))
    call assert_equal('javascript', luis#detect_filetype('foo.js', []))
    call assert_equal('vim', luis#detect_filetype('foo.vim', []))
    call assert_equal('html', luis#detect_filetype('foo.html', ['<!DOCTYPE html>']))
  finally
    filetype off
  endtry
endfunction

function! s:test_do_action__with_defined_action() abort
  let action_spy = Spy({ candidate, context -> 0 })

  let kind = CreateMockKind()
  let kind.action_table.default  = action_spy.to_funcref()
  let source = CreateMockSource({ 'default_kind': kind })
  let session = CreateMockSession(source, {}, {}, 1)

  let candidate = { 'word': 'VIM' }
  let context = { 'kind': kind, 'session': session }

  call assert_equal(0, luis#do_action('default', candidate, context))
  call assert_equal(1, action_spy.call_count())
  call assert_equal([candidate, context], action_spy.last_args())
  call assert_equal(0, action_spy.last_return_value())
endfunction

function! s:test_do_action__with_undefined_action() abort
  let source = CreateMockSource()
  let session = CreateMockSession(source, {}, {}, 1)

  let candidate = { 'word': 'VIM' }
  let context = { 'session': session, 'kind': source.default_kind }

  call assert_equal(
  \   "luis: Action 'XXX' not defined",
  \   luis#do_action('XXX', candidate, context)
  \ )
endfunction

function! s:test_preview_candidate__with_buffer_preview() abort
  let [source, source_spies] = SpyDict(CreateMockSource())
  let [hook, hook_spies] = SpyDict(CreateMockHook())
  let [preview, preview_spies] = SpyDict(CreateMockPreviewWindow(1))

  " With existent buffer
  let candidate = {
  \   'word': 'foo',
  \   'user_data': {
  \     'preview_bufnr': bufnr('%'),
  \     'preview_cursor': [10, 1],
  \   }
  \ }
  let [session, session_spies] = SpyDict(CreateMockSession(source, hook, candidate, 1))
  let bounds = { 'row': 2, 'col': 3, 'width': 4, 'height': 5 }

  call luis#preview_candidate(session, preview, bounds)

  call assert_equal(1, session_spies.guess_candidate.call_count())
  call assert_equal(1, source_spies.on_preview.call_count())
  call assert_equal([
  \   candidate,
  \   { 'session': session, 'preview': preview },
  \ ], source_spies.on_preview.last_args())
  call assert_equal(1, hook_spies.on_preview.call_count())
  call assert_equal([
  \   candidate,
  \   { 'session': session, 'preview': preview },
  \ ], hook_spies.on_preview.last_args())
  call assert_equal(1, preview_spies.open_buffer.call_count())
  call assert_equal(
  \   [
  \     candidate.user_data.preview_bufnr,
  \     bounds,
  \     { 'cursor': candidate.user_data.preview_cursor }
  \   ],
  \   preview_spies.open_buffer.last_args()
  \ )
  call assert_equal(0, preview_spies.close.call_count())

  " With non-existent buffer
  let candidate = {
  \   'word': 'foo',
  \   'user_data': {
  \     'preview_bufnr': bufnr('$') + 1,
  \   }
  \ }
  let [session, session_spies] = SpyDict(CreateMockSession(source, hook, candidate, 1))
  let bounds = { 'row': 2, 'col': 3, 'width': 4, 'height': 5 }

  call luis#preview_candidate(session, preview, bounds)

  call assert_equal(1, session_spies.guess_candidate.call_count())
  call assert_equal(2, source_spies.on_preview.call_count())
  call assert_equal([
  \   candidate,
  \   { 'session': session, 'preview': preview },
  \ ], source_spies.on_preview.last_args())
  call assert_equal(2, hook_spies.on_preview.call_count())
  call assert_equal([
  \   candidate,
  \   { 'session': session, 'preview': preview },
  \ ], hook_spies.on_preview.last_args())
  call assert_equal(1, preview_spies.open_buffer.call_count())
  call assert_equal(1, preview_spies.close.call_count())
endfunction

function! s:test_preview_candidate__with_file_preview() abort
  if !has('nvim') && !exists('*popup_create')
    return 'popup_create() function is required.'
  endif

  let [source, source_spies] = SpyDict(CreateMockSource())
  let [hook, hook_spies] = SpyDict(CreateMockHook())
  let [preview, preview_spies] = SpyDict(CreateMockPreviewWindow(1))

  filetype on

  try
    " With filetype
    let candidate = {
    \   'word': 'foo',
    \   'user_data': {
    \     'preview_path': 'test/data/seq.txt',
    \     'preview_filetype': 'help',
    \   }
    \ }
    let [session, session_spies] = SpyDict(CreateMockSession(source, hook, candidate, 1))
    let bounds = { 'row': 1, 'col': 2, 'width': 3, 'height': 4 }

    call luis#preview_candidate(session, preview, bounds)

    call assert_equal(1, session_spies.guess_candidate.call_count())
    call assert_equal(1, source_spies.on_preview.call_count())
    call assert_equal([
    \   candidate,
    \   { 'session': session, 'preview': preview },
    \ ], source_spies.on_preview.last_args())
    call assert_equal(1, hook_spies.on_preview.call_count())
    call assert_equal([
    \   candidate,
    \   { 'session': session, 'preview': preview },
    \ ], hook_spies.on_preview.last_args())
    call assert_equal(1, preview_spies.open_text.call_count())
    call assert_equal(
    \   [
    \     ['1', '2', '3', '4'],
    \     bounds,
    \     { 'filetype': 'help' },
    \   ],
    \   preview_spies.open_text.last_args()
    \ )
    call assert_equal(0, preview_spies.close.call_count())

    " Without filetype (Auto detection)
    let candidate = {
    \   'word': 'hello_world.vim',
    \   'user_data': {
    \     'preview_path': 'test/data/hello_world.vim',
    \   }
    \ }
    let [session, session_spies] = SpyDict(CreateMockSession(source, hook, candidate, 1))
    let bounds = { 'row': 2, 'col': 3, 'width': 4, 'height': 5 }

    call luis#preview_candidate(session, preview, bounds)

    call assert_equal(1, session_spies.guess_candidate.call_count())
    call assert_equal(2, source_spies.on_preview.call_count())
    call assert_equal([
    \   candidate,
    \   { 'session': session, 'preview': preview },
    \ ], source_spies.on_preview.last_args())
    call assert_equal(2, hook_spies.on_preview.call_count())
    call assert_equal([
    \   candidate,
    \   { 'session': session, 'preview': preview },
    \ ], hook_spies.on_preview.last_args())
    call assert_equal(2, preview_spies.open_text.call_count())
    call assert_equal(
    \   [
    \     ["echo 'hello, world!'"],
    \     bounds,
    \     { 'filetype': 'vim' },
    \   ],
    \   preview_spies.open_text.last_args()
    \ )
    call assert_equal(0, preview_spies.close.call_count())

    " With non-existent file
    let candidate = {
    \   'word': 'foo',
    \   'user_data': {
    \     'preview_path': tempname(),
    \   }
    \ }
    let [session, session_spies] = SpyDict(CreateMockSession(source, hook, candidate, 1))
    let bounds = { 'row': 3, 'col': 4, 'width': 5, 'height': 6 }

    call luis#preview_candidate(session, preview, bounds)

    call assert_equal(1, session_spies.guess_candidate.call_count())
    call assert_equal(3, source_spies.on_preview.call_count())
    call assert_equal([
    \   candidate,
    \   { 'session': session, 'preview': preview },
    \ ], source_spies.on_preview.last_args())
    call assert_equal(3, hook_spies.on_preview.call_count())
    call assert_equal([
    \   candidate,
    \   { 'session': session, 'preview': preview },
    \ ], hook_spies.on_preview.last_args())
    call assert_equal(2, preview_spies.open_text.call_count())
    call assert_equal(1, preview_spies.close.call_count())
  finally
    filetype off
  endtry
endfunction

function! s:test_preview_candidate__with_no_preview() abort
  let [source, source_spies] = SpyDict(CreateMockSource())
  let [hook, hook_spies] = SpyDict(CreateMockHook())
  let [preview, preview_spies] = SpyDict(CreateMockPreviewWindow(1))

  let candidate = { 'word': '', 'user_data': {} }
  let [session, session_spies] = SpyDict(CreateMockSession(source, hook, candidate, 1))
  let bounds = { 'row': 1, 'col': 2, 'width': 3, 'height': 4 }

  call luis#preview_candidate(session, preview, bounds)

  call assert_equal(1, session_spies.guess_candidate.call_count())
  call assert_equal(1, source_spies.on_preview.call_count())
  call assert_equal([
  \   candidate,
  \   { 'session': session, 'preview': preview },
  \ ], source_spies.on_preview.last_args())
  call assert_equal(1, hook_spies.on_preview.call_count())
  call assert_equal([
  \   candidate,
  \   { 'session': session, 'preview': preview },
  \ ], hook_spies.on_preview.last_args())
  call assert_equal(1, preview_spies.close.call_count())
endfunction

function! s:test_preview_candidate__with_text_preview() abort
  let [source, source_spies] = SpyDict(CreateMockSource())
  let [hook, hook_spies] = SpyDict(CreateMockHook())
  let [preview, preview_spies] = SpyDict(CreateMockPreviewWindow(1))

  let candidate = {
  \   'word': 'foo',
  \   'user_data': {
  \     'preview_title': 'title',
  \     'preview_lines': ['foo', 'bar', 'baz'],
  \   }
  \ }
  let [session, session_spies] = SpyDict(CreateMockSession(source, hook, candidate, 1))
  let bounds = { 'row': 1, 'col': 2, 'width': 3, 'height': 4 }

  call luis#preview_candidate(session, preview, bounds)

  call assert_equal(1, session_spies.guess_candidate.call_count())
  call assert_equal(1, source_spies.on_preview.call_count())
  call assert_equal([
  \   candidate,
  \   { 'session': session, 'preview': preview },
  \ ], source_spies.on_preview.last_args())
  call assert_equal(1, hook_spies.on_preview.call_count())
  call assert_equal([
  \   candidate,
  \   { 'session': session, 'preview': preview },
  \ ], hook_spies.on_preview.last_args())
  call assert_equal(1, preview_spies.open_text.call_count())
  call assert_equal(
  \   [
  \     candidate.user_data.preview_lines,
  \     bounds,
  \     { 'title': candidate.user_data.preview_title }
  \   ],
  \   preview_spies.open_text.last_args()
  \ )
  call assert_equal(0, preview_spies.close.call_count())
endfunction

function! s:test_quit__with_active_session() abort
  let [source, source_spies] = SpyDict(CreateMockSource())
  let [hook, hook_spies] = SpyDict(CreateMockHook())
  let [session, session_spies] = SpyDict(CreateMockSession(source, hook, {}, 1))

  call assert_true(luis#quit(session))
  call assert_equal(1, session_spies.quit.call_count())
  call assert_equal(0, source_spies.on_source_enter.call_count())
  call assert_equal(1, source_spies.on_source_leave.call_count())
  call assert_equal(
  \   [{ 'session': session }],
  \   source_spies.on_source_leave.last_args()
  \ )
  call assert_equal(source, source_spies.on_source_leave.last_self())
  call assert_equal(0, hook_spies.on_source_enter.call_count())
  call assert_equal(1, hook_spies.on_source_leave.call_count())
  call assert_equal(
  \   [{ 'session': session }],
  \   hook_spies.on_source_leave.last_args()
  \ )
  call assert_equal(hook, hook_spies.on_source_leave.last_self())
endfunction

function! s:test_quit__with_not_active_session() abort
  let [source, source_spies] = SpyDict(CreateMockSource())
  let [hook, hook_spies] = SpyDict(CreateMockHook())
  let [session, session_spies] = SpyDict(CreateMockSession(source, hook, {}, 0))

  redir => OUTPUT
  silent call assert_false(luis#quit(session))
  redir END

  call assert_match('luis: Session not active', OUTPUT)
  call assert_equal(0, session_spies.quit.call_count())
  call assert_equal(0, source_spies.on_source_enter.call_count())
  call assert_equal(0, source_spies.on_source_leave.call_count())
  call assert_equal(0, hook_spies.on_source_enter.call_count())
  call assert_equal(0, hook_spies.on_source_leave.call_count())
endfunction

function! s:test_start__with_valid_session() abort
  let [source, source_spies] = SpyDict(CreateMockSource())
  let [hook, hook_spies] = SpyDict(CreateMockHook())
  let [session, session_spies] = SpyDict(CreateMockSession(source, hook, {}, 0))

  call assert_true(luis#start(session))
  call assert_equal(1, session_spies.start.call_count())
  call assert_equal(1, source_spies.on_source_enter.call_count())
  call assert_equal(
  \   [{ 'session': session }],
  \   source_spies.on_source_enter.last_args()
  \ )
  call assert_equal(source, source_spies.on_source_enter.last_self())
  call assert_equal(0, source_spies.on_source_leave.call_count())
  call assert_equal(1, hook_spies.on_source_enter.call_count())
  call assert_equal(
  \   [{ 'session': session }],
  \   hook_spies.on_source_enter.last_args()
  \ )
  call assert_equal(hook, hook_spies.on_source_enter.last_self())
  call assert_equal(0, hook_spies.on_source_leave.call_count())
endfunction

function! s:test_start__with_active_session() abort
  let [source, source_spies] = SpyDict(CreateMockSource())
  let [hook, hook_spies] = SpyDict(CreateMockHook())
  let [session, session_spies] = SpyDict(CreateMockSession(source, hook, {}, 1))

  redir => OUTPUT
  silent call assert_false(luis#start(session))
  redir END

  call assert_match('luis: Session already active', OUTPUT)
  call assert_equal(0, session_spies.start.call_count())
  call assert_equal(0, source_spies.on_source_enter.call_count())
  call assert_equal(0, source_spies.on_source_leave.call_count())
  call assert_equal(0, hook_spies.on_source_enter.call_count())
  call assert_equal(0, hook_spies.on_source_leave.call_count())
endfunction

function! s:test_start__with_invalid_session() abort
  let v:errmsg = ''
  silent! call luis#start({})
  call assert_match('luis: Invalid Session:', v:errmsg)
endfunction

function! s:test_take_action__choose_action() abort
  let candidate = { 'word': 'VIM', 'user_data': {} }
  let [source, source_spies] = SpyDict(CreateMockSource())
  let [hook, hook_spies] = SpyDict(CreateMockHook())
  let [session, session_spies] = SpyDict(CreateMockSession(source, hook, candidate, 1))

  let action_spy = Spy({ candidate, context -> 0 })
  let kind = session.source.default_kind
  let kind.action_table.default = action_spy.to_funcref()

  call feedkeys("\<CR>", 'nt')
  silent call assert_true(luis#take_action(session))
  call assert_equal(0, getchar(0))

  let context = { 'kind': kind, 'session': session }

  call assert_equal(1, session_spies.quit.call_count())

  call assert_equal(1, source_spies.on_action.call_count())
  call assert_equal([candidate, context], source_spies.on_action.last_args())
  call assert_equal(source, source_spies.on_action.last_self())
  call assert_equal(1, source_spies.on_source_leave.call_count())
  call assert_equal(
  \   [{ 'session': session }],
  \   source_spies.on_source_leave.last_args()
  \ )
  call assert_equal(source, source_spies.on_source_leave.last_self())

  call assert_equal(1, hook_spies.on_action.call_count())
  call assert_equal([candidate, context], hook_spies.on_action.last_args())
  call assert_equal(hook, hook_spies.on_action.last_self())
  call assert_equal(1, hook_spies.on_source_leave.call_count())
  call assert_equal(
  \   [{ 'session': session }],
  \   hook_spies.on_source_leave.last_args()
  \ )
  call assert_equal(hook, hook_spies.on_source_leave.last_self())

  call assert_equal(1, action_spy.call_count())
  call assert_equal([candidate, context], action_spy.last_args())
  call assert_equal(0, action_spy.last_return_value())
endfunction

function! s:test_take_action__do_default_action() abort
  let candidate = { 'word': 'VIM', 'user_data': {} }
  let source = CreateMockSource()
  let [session, session_spies] = SpyDict(CreateMockSession(source, {}, candidate, 1))

  let action_spy = Spy({ candidate, context -> 0 })
  let kind = session.source.default_kind
  let kind.action_table.default = action_spy.to_funcref()

  silent call assert_true(luis#take_action(session, 'default'))

  let expected_context = { 'kind': kind, 'session': session }

  call assert_equal(1, action_spy.call_count())
  call assert_equal([candidate, expected_context], action_spy.last_args())
  call assert_equal(0, action_spy.last_return_value())
endfunction

function! s:test_take_action__session_is_not_active() abort
  let source = CreateMockSource()
  let [session, session_spies] = SpyDict(CreateMockSession(source, {}, {}, 0))

  redir => OUTPUT
  silent call assert_false(luis#take_action(session, 'default'))
  redir END

  call assert_match('luis: Session not active', OUTPUT)
endfunction

function! s:test_take_action__with_candidate_kind() abort
  let action_spy = Spy({ candidate, context -> 0 })

  let kind = CreateMockKind()
  let kind.action_table.default  = action_spy.to_funcref()
  let candidate = { 'word': 'VIM', 'user_data': { 'kind': kind } }
  let source = CreateMockSource()
  let session = CreateMockSession(source, {}, candidate, 1)

  silent call assert_true(luis#take_action(session, 'default'))

  let expected_context = { 'kind': kind, 'session': session }

  call assert_equal(1, action_spy.call_count())
  call assert_equal([candidate, expected_context], action_spy.last_args())
  call assert_equal(0, action_spy.last_return_value())
endfunction
