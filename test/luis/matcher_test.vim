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
  call assert_equal('usr', luis#matcher#acc_text('/', cs1, source))
  call assert_equal('usr', luis#matcher#acc_text('u/', cs1, source))
  call assert_equal('usr', luis#matcher#acc_text('s/', cs1, source))
  call assert_equal('usr/share', luis#matcher#acc_text('sh/', cs1, source))
  call assert_equal('usr/share/man', luis#matcher#acc_text('m/', cs1, source))
  call assert_equal('usr/share/man/man1', luis#matcher#acc_text('1/', cs1, source))

  call assert_equal('usr/share/w y 1', luis#matcher#acc_text('w/', cs2, source))
  call assert_equal('usr/share/ x z2', luis#matcher#acc_text('x/', cs2, source))
  call assert_equal('usr/share/w y 1', luis#matcher#acc_text('y/', cs2, source))
  call assert_equal('usr/share/ x z2', luis#matcher#acc_text('z/', cs2, source))

  call assert_equal('bin', luis#matcher#acc_text('b/', cs3, source))
  call assert_equal('etc', luis#matcher#acc_text('e/', cs3, source))
  call assert_equal('usr', luis#matcher#acc_text('r/', cs3, source))
  call assert_equal('usr', luis#matcher#acc_text('u/', cs3, source))
  call assert_equal('var', luis#matcher#acc_text('v/', cs3, source))

  call assert_equal('3/X', luis#matcher#acc_text('X/', cs4, source))

  " len(components) >= 3
  call assert_equal('usr/share', luis#matcher#acc_text('usr//', cs1, source))
  call assert_equal('usr/share', luis#matcher#acc_text('usr/s/', cs1, source))
  call assert_equal('usr/share', luis#matcher#acc_text('usr/sh/', cs1, source))
  call assert_equal('usr/share/man', luis#matcher#acc_text('usr/m/', cs1, source))
  call assert_equal('usr/share/man/man1', luis#matcher#acc_text('usr/1/', cs1, source))
  call assert_equal('usr/share', luis#matcher#acc_text('usr/share/', cs1, source))

  call assert_equal('usr/share/man', luis#matcher#acc_text('usr/share//', cs1, source))
  call assert_equal('usr/share/man', luis#matcher#acc_text('usr/share/m/', cs1, source))
  call assert_equal('usr/share/man/man1', luis#matcher#acc_text('usr/share/1/', cs1, source))

  call assert_equal('etc/2', luis#matcher#acc_text('etc//', cs3, source))
  call assert_equal('var/4', luis#matcher#acc_text('var//', cs3, source))

  " No components
  let v:errmsg = ''
  silent! call luis#matcher#acc_text('', [], source)
  call assert_match('luis: Assumption on ACC is failed:', v:errmsg)

  let v:errmsg = ''
  silent! call assert_equal('', luis#matcher#acc_text('', cs1, source))
  call assert_match('luis: Assumption on ACC is failed:', v:errmsg)

  " No proper candidate for a:pattern
  call assert_equal('', luis#matcher#acc_text('x/', [], source))
  call assert_equal('', luis#matcher#acc_text('x/', cs1, source))
  call assert_equal('', luis#matcher#acc_text('2/', cs1, source))
  call assert_equal('', luis#matcher#acc_text('u/s/m/', cs1, source))
  call assert_equal('', luis#matcher#acc_text('USR//', cs1, source))
endfunction

function! s:test_collect_candidates__with_default_matcher() abort
  let candidates = [
  \   { 'word': 'foo' },
  \   { 'word': 'foobar' },
  \   { 'word': 'foobarbaz' },
  \ ]
  let [matcher, matcher_spies] = SpyDict(CreateMockMatcher())
  let [source, source_spies] = SpyDict(CreateMockSource({
  \   'candidates': candidates,
  \ }))
  let session = CreateMockSession(source, {}, {}, 1)
  let normalize_spy = Spy({ candidate -> candidate })

  let pattern = 'foo'
  let expected_context = {
  \   'pattern': pattern,
  \   'matcher': matcher,
  \   'session': session,
  \ }

  let original_matcher = luis#matcher#set_default(matcher)

  call assert_equal(
  \   candidates,
  \   luis#matcher#collect_candidates(
  \     session,
  \     pattern,
  \     normalize_spy.to_funcref()
  \   )
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
  \ ], matcher_spies.normalize_candidate.args())
  call assert_equal([
  \   [candidates[0], 0, expected_context],
  \   [candidates[1], 1, expected_context],
  \   [candidates[2], 2, expected_context],
  \ ], normalize_spy.args())
  call assert_equal(1, matcher_spies.sort_candidates.call_count())
  call assert_equal(
  \   [candidates, expected_context],
  \   matcher_spies.sort_candidates.last_args()
  \ )

  call luis#matcher#set_default(original_matcher)
endfunction

function! s:test_collect_candidates__with_hook() abort
  let candidates = [
  \   { 'word': 'foo' },
  \   { 'word': 'foobar' },
  \   { 'word': 'foobarbaz' },
  \ ]
  let [matcher, matcher_spies] = SpyDict(CreateMockMatcher())
  let [source, source_spies] = SpyDict(CreateMockSource({
  \   'matcher': matcher,
  \   'candidates': candidates,
  \ }))
  let [hook, hook_spies] = SpyDict(CreateMockHook())
  let session = CreateMockSession(source, hook, {}, 1)
  let normalize_spy = Spy({ candidate -> candidate })

  let pattern = 'foo'
  let expected_context = {
  \   'pattern': pattern,
  \   'matcher': matcher,
  \   'session': session,
  \ }

  call assert_equal(
  \   candidates,
  \   luis#matcher#collect_candidates(
  \     session,
  \     pattern,
  \     normalize_spy.to_funcref()
  \   )
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
  \ ], hook_spies.format_candidate.args())
  call assert_equal([
  \   [candidates[0], 0, expected_context],
  \   [candidates[1], 1, expected_context],
  \   [candidates[2], 2, expected_context],
  \ ], matcher_spies.normalize_candidate.args())
  call assert_equal([
  \   [candidates[0], 0, expected_context],
  \   [candidates[1], 1, expected_context],
  \   [candidates[2], 2, expected_context],
  \ ], normalize_spy.args())
  call assert_equal(1, matcher_spies.sort_candidates.call_count())
  call assert_equal(
  \   [candidates, expected_context],
  \   matcher_spies.sort_candidates.last_args()
  \ )
endfunction

function! s:test_collect_candidates__with_source_matcher() abort
  let candidates = [
  \   { 'word': 'foo' },
  \   { 'word': 'foobar' },
  \   { 'word': 'foobarbaz' },
  \ ]
  let [matcher, matcher_spies] = SpyDict(CreateMockMatcher())
  let [source, source_spies] = SpyDict(CreateMockSource({
  \   'matcher': matcher,
  \   'candidates': candidates,
  \ }))
  let session = CreateMockSession(source, {}, {}, 1)
  let normalize_spy = Spy({ candidate -> candidate })

  let pattern = 'foo'
  let expected_context = {
  \   'pattern': pattern,
  \   'matcher': matcher,
  \   'session': session,
  \ }

  call assert_equal(
  \   candidates,
  \   luis#matcher#collect_candidates(
  \     session,
  \     pattern,
  \     normalize_spy.to_funcref()
  \   )
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
  \ ], matcher_spies.normalize_candidate.args())
  call assert_equal([
  \   [candidates[0], 0, expected_context],
  \   [candidates[1], 1, expected_context],
  \   [candidates[2], 2, expected_context],
  \ ], normalize_spy.args())
  call assert_equal(1, matcher_spies.sort_candidates.call_count())
  call assert_equal(
  \   [candidates, expected_context],
  \   matcher_spies.sort_candidates.last_args()
  \ )
endfunction

function! s:test_set_default() abort
  let original_matcher = luis#matcher#default()
  call assert_equal(1, luis#validations#validate_matcher(original_matcher))

  let new_matcher = CreateMockMatcher()
  let old_matcher = luis#matcher#set_default(new_matcher)
  call assert_true(old_matcher is original_matcher)

  let matcher = luis#matcher#default()
  call assert_true(matcher is new_matcher)

  let old_matcher = luis#matcher#set_default(original_matcher)
  call assert_true(old_matcher is new_matcher)

  let matcher = luis#matcher#default()
  call assert_true(matcher is original_matcher)
endfunction

function! s:test_set_default__invalid_matcher() abort
  let v:errmsg = ''
  silent! call luis#matcher#set_default({})
  call assert_match('luis: Invalid Matcher:', v:errmsg)
endfunction
