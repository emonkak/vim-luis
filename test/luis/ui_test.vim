silent runtime! test/mocks.vim
silent runtime! test/spy.vim

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
  call assert_equal('usr', luis#ui#acc_text('/', cs1, source))
  call assert_equal('usr', luis#ui#acc_text('u/', cs1, source))
  call assert_equal('usr', luis#ui#acc_text('s/', cs1, source))
  call assert_equal('usr/share', luis#ui#acc_text('sh/', cs1, source))
  call assert_equal('usr/share/man', luis#ui#acc_text('m/', cs1, source))
  call assert_equal('usr/share/man/man1', luis#ui#acc_text('1/', cs1, source))

  call assert_equal('usr/share/w y 1', luis#ui#acc_text('w/', cs2, source))
  call assert_equal('usr/share/ x z2', luis#ui#acc_text('x/', cs2, source))
  call assert_equal('usr/share/w y 1', luis#ui#acc_text('y/', cs2, source))
  call assert_equal('usr/share/ x z2', luis#ui#acc_text('z/', cs2, source))

  call assert_equal('bin', luis#ui#acc_text('b/', cs3, source))
  call assert_equal('etc', luis#ui#acc_text('e/', cs3, source))
  call assert_equal('usr', luis#ui#acc_text('r/', cs3, source))
  call assert_equal('usr', luis#ui#acc_text('u/', cs3, source))
  call assert_equal('var', luis#ui#acc_text('v/', cs3, source))

  call assert_equal('3/X', luis#ui#acc_text('X/', cs4, source))

  " len(components) >= 3
  call assert_equal('usr/share', luis#ui#acc_text('usr//', cs1, source))
  call assert_equal('usr/share', luis#ui#acc_text('usr/s/', cs1, source))
  call assert_equal('usr/share', luis#ui#acc_text('usr/sh/', cs1, source))
  call assert_equal('usr/share/man', luis#ui#acc_text('usr/m/', cs1, source))
  call assert_equal('usr/share/man/man1', luis#ui#acc_text('usr/1/', cs1, source))
  call assert_equal('usr/share', luis#ui#acc_text('usr/share/', cs1, source))

  call assert_equal('usr/share/man', luis#ui#acc_text('usr/share//', cs1, source))
  call assert_equal('usr/share/man', luis#ui#acc_text('usr/share/m/', cs1, source))
  call assert_equal('usr/share/man/man1', luis#ui#acc_text('usr/share/1/', cs1, source))

  call assert_equal('etc/2', luis#ui#acc_text('etc//', cs3, source))
  call assert_equal('var/4', luis#ui#acc_text('var//', cs3, source))

  " No components
  let v:errmsg = ''
  silent! call luis#ui#acc_text('', [], source)
  call assert_match('luis: Assumption on ACC is failed:', v:errmsg)

  let v:errmsg = ''
  silent! call assert_equal('', luis#ui#acc_text('', cs1, source))
  call assert_match('luis: Assumption on ACC is failed:', v:errmsg)

  " No proper candidate for a:pattern
  call assert_equal('', luis#ui#acc_text('x/', [], source))
  call assert_equal('', luis#ui#acc_text('x/', cs1, source))
  call assert_equal('', luis#ui#acc_text('2/', cs1, source))
  call assert_equal('', luis#ui#acc_text('u/s/m/', cs1, source))
  call assert_equal('', luis#ui#acc_text('USR//', cs1, source))
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

  let original_matcher = g:luis#ui#default_matcher
  let original_comparer = g:luis#ui#default_comparer
  let g:luis#ui#default_matcher = matcher
  let g:luis#ui#default_comparer = comparer

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
    \   luis#ui#collect_candidates(session, pattern)
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
    let g:luis#ui#default_comparer = original_comparer
    let g:luis#ui#default_matcher = original_matcher
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

  let original_matcher = g:luis#ui#default_matcher
  let g:luis#ui#default_matcher = default_matcher

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
    \   luis#ui#collect_candidates(session, pattern)
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
    let g:luis#ui#default_matcher = original_matcher
  endtry
endfunction

function! s:test_default_comparer() abort
  let comparer = g:luis#ui#default_comparer

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
