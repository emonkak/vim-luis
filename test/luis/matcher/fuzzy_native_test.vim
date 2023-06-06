silent runtime! test/mocks.vim
silent runtime! test/spy.vim

let s:matcher = luis#matcher#fuzzy_native#import()

function! s:test_filter_candidates() abort
  if !exists('*matchfuzzypos')
    return 'matchfuzzypos() function is required.'
  endif

  let cs = [
  \   { 'word': 'foo' },
  \   { 'word': 'foobar' },
  \   { 'word': 'foobarbaz' },
  \ ]

  call assert_equal([
  \   { 'word': 'foo' },
  \   { 'word': 'foobar' },
  \   { 'word': 'foobarbaz' },
  \ ], s:matcher.filter_candidates(cs, { 'pattern': '' }))
  call assert_equal([
  \   { 'word': 'foo' },
  \   { 'word': 'foobar' },
  \   { 'word': 'foobarbaz' },
  \ ], s:matcher.filter_candidates(cs, { 'pattern': 'foo' }))
  call assert_equal([
  \   { 'word': 'foobar' },
  \   { 'word': 'foobarbaz' },
  \ ], s:matcher.filter_candidates(cs, { 'pattern': 'bar' }))
  call assert_equal([
  \   { 'word': 'foobarbaz' },
  \ ], s:matcher.filter_candidates(cs, { 'pattern': 'baz' }))
  call assert_equal([], s:matcher.filter_candidates(cs, { 'pattern': 'qux' }))

  call assert_equal([
  \   { 'word': 'foobar' },
  \   { 'word': 'foobarbaz' },
  \ ], s:matcher.filter_candidates(cs, { 'pattern': 'foobar' }))
  call assert_equal([
  \   { 'word': 'foobarbaz' },
  \ ], s:matcher.filter_candidates(cs, { 'pattern': 'foobaz' }))
  call assert_equal(
  \   [],
  \   s:matcher.filter_candidates(cs, { 'pattern': 'foobarbar' })
  \ )
  call assert_equal([
  \   { 'word': 'foobarbaz' },
  \ ], s:matcher.filter_candidates(cs, { 'pattern': 'foobarbaz' }))

  call assert_equal([
  \   { 'word': 'foobar' },
  \   { 'word': 'foobarbaz' },
  \ ], s:matcher.filter_candidates(cs, { 'pattern': 'fb' }))
  call assert_equal([
  \   { 'word': 'foobarbaz' },
  \ ], s:matcher.filter_candidates(cs, { 'pattern': 'fbb' }))
endfunction

function! s:test_matcher_definition() abort
  call assert_true(luis#validate_matcher(s:matcher))
endfunction

function! s:test_normalize_candidate() abort
  let candidate = { 'word': 'foo' }
  let index = 0
  let context = { '_match_positions': [[0]], '_match_scores': [100] }
  call assert_equal({
  \   'word': 'foo',
  \   'luis_match_positions': [0],
  \   'luis_match_score': 100,
  \   'luis_match_priority': 0,
  \ }, s:matcher.normalize_candidate(candidate, index, context))

  let candidate = { 'word': 'foo', 'luis_match_priority': 1 }
  let index = 0
  let context = { '_match_positions': [[0]], '_match_scores': [100] }
  call assert_equal({
  \   'word': 'foo',
  \   'luis_match_positions': [0],
  \   'luis_match_score': 100,
  \   'luis_match_priority': 1,
  \ }, s:matcher.normalize_candidate(candidate, index, context))
endfunction

function! s:test_sort_candidates() abort
  let cs1 = [
  \   {
  \     'word': '/BIN',
  \     'luis_match_positions': [0, 1],
  \     'luis_match_priority': 0,
  \     'luis_match_score': 950,
  \   },
  \   {
  \     'word': '/bin',
  \     'luis_match_positions': [0, 1],
  \     'luis_match_priority': 0,
  \     'luis_match_score': 950,
  \   },
  \   {
  \     'word': '/lib',
  \     'luis_match_positions': [0, 3],
  \     'luis_match_priority': 0,
  \     'luis_match_score': 500,
  \   },
  \   {
  \     'word': '/sbin',
  \     'luis_match_positions': [0, 2],
  \     'luis_match_priority': 0,
  \     'luis_match_score': 760,
  \   },
  \ ]
  let cs2 = [
  \   {
  \     'word': '/BIN',
  \     'luis_match_positions': [0, 1],
  \     'luis_match_priority': 0,
  \     'luis_match_score': 950,
  \   },
  \   {
  \     'word': '/bin',
  \     'luis_match_positions': [0, 1],
  \     'luis_match_priority': 0,
  \     'luis_match_score': 950,
  \   },
  \   {
  \     'word': '/lib',
  \     'luis_match_positions': [0, 3],
  \     'luis_match_priority': 1,
  \     'luis_match_score': 500,
  \   },
  \   {
  \     'word': '/sbin',
  \     'luis_match_positions': [0, 2],
  \     'luis_match_priority': 1,
  \     'luis_match_score': 760,
  \   },
  \ ]

  let [comparer, comparer_spies] = SpyDict(CreateMockComparer())
  let session = {
  \   'id': 1,
  \   'source': CreateMockSource(),
  \   'ui': CreateMockUI(),
  \   'matcher': CreateMockMatcher(),
  \   'comparer': comparer,
  \   'previewer': CreateMockPreviewer(),
  \   'hook': CreateMockHook(),
  \   'initial_pattern': '',
  \ }
  let context = { 'session': session }
  call assert_equal(
  \   [cs1[0], cs1[1], cs1[3], cs1[2]],
  \   s:matcher.sort_candidates(copy(cs1), context)
  \ )
  call assert_true(comparer_spies.compare_candidates.called())

  let [comparer, comparer_spies] = SpyDict(CreateMockComparer())
  let session = {
  \   'id': 1,
  \   'source': CreateMockSource(),
  \   'ui': CreateMockUI(),
  \   'matcher': CreateMockMatcher(),
  \   'comparer': comparer,
  \   'previewer': CreateMockPreviewer(),
  \   'hook': CreateMockHook(),
  \   'initial_pattern': '',
  \ }
  let context = { 'session': session }
  call assert_equal(
  \   [cs2[3], cs2[2], cs2[0], cs2[1]],
  \   s:matcher.sort_candidates(copy(cs2), context)
  \ )
  call assert_true(comparer_spies.compare_candidates.called())
endfunction
