silent runtime! test/mocks.vim
silent runtime! test/spy.vim

let s:matcher = luis#matcher#fuzzy#import()

function! s:test_filter_candidates() abort
  let cs1 = [
  \   { 'word': 'foo' },
  \   { 'word': 'foobar' },
  \   { 'word': 'foobarbaz', 'luis_match_priority': 1 },
  \ ]

  call assert_equal([
  \   {
  \     'word': 'foo',
  \     'luis_match_positions': [],
  \     'luis_match_priority': 0,
  \     'luis_match_score': 900,
  \   },
  \   {
  \     'word': 'foobar',
  \     'luis_match_positions': [],
  \     'luis_match_priority': 0,
  \     'luis_match_score': 900,
  \   },
  \   {
  \     'word': 'foobarbaz',
  \     'luis_match_positions': [],
  \     'luis_match_priority': 1,
  \     'luis_match_score': 900,
  \   },
  \ ], s:matcher.filter_candidates(cs1, { 'pattern': '' }))
  call assert_equal([
  \   {
  \     'word': 'foo',
  \     'luis_match_positions': [0, 1, 2],
  \     'luis_match_priority': 0,
  \     'luis_match_score': 1000,
  \   },
  \   {
  \     'word': 'foobar',
  \     'luis_match_positions': [0, 1, 2],
  \     'luis_match_priority': 0,
  \     'luis_match_score': 950,
  \   },
  \   {
  \     'word': 'foobarbaz',
  \     'luis_match_positions': [0, 1, 2],
  \     'luis_match_priority': 1,
  \     'luis_match_score': 933,
  \   },
  \ ], s:matcher.filter_candidates(cs1, { 'pattern': 'foo' }))
  call assert_equal([
  \   {
  \     'word': 'foobar',
  \     'luis_match_positions': [3, 4, 5],
  \     'luis_match_priority': 0,
  \     'luis_match_score': 500,
  \   },
  \   {
  \     'word': 'foobarbaz',
  \     'luis_match_positions': [3, 4, 5],
  \     'luis_match_priority': 1,
  \     'luis_match_score': 633,
  \   },
  \ ], s:matcher.filter_candidates(cs1, { 'pattern': 'bar' }))
  call assert_equal([
  \   {
  \     'word': 'foobarbaz',
  \     'luis_match_positions': [6, 7, 8],
  \     'luis_match_priority': 1,
  \     'luis_match_score': 333,
  \   },
  \ ], s:matcher.filter_candidates(cs1, { 'pattern': 'baz' }))
  call assert_equal([], s:matcher.filter_candidates(cs1, { 'pattern': 'qux' }))

  call assert_equal([
  \   {
  \     'word': 'foobar',
  \     'luis_match_positions': [0, 1, 2, 3, 4, 5],
  \     'luis_match_priority': 0,
  \     'luis_match_score': 1000,
  \   },
  \   {
  \     'word': 'foobarbaz',
  \     'luis_match_positions': [0, 1, 2, 3, 4, 5],
  \     'luis_match_priority': 1,
  \     'luis_match_score': 967,
  \   },
  \ ], s:matcher.filter_candidates(cs1, { 'pattern': 'foobar' }))
  call assert_equal([
  \   {
  \     'word': 'foobarbaz',
  \     'luis_match_positions': [0, 1, 2, 3, 4, 8],
  \     'luis_match_priority': 1,
  \     'luis_match_score': 667,
  \   },
  \ ], s:matcher.filter_candidates(cs1, { 'pattern': 'foobaz' }))
  call assert_equal(
  \   [],
  \   s:matcher.filter_candidates(cs1, { 'pattern': 'foobarbar' })
  \ )
  call assert_equal([
  \   {
  \     'word': 'foobarbaz',
  \     'luis_match_positions': [0, 1, 2, 3, 4, 5, 6, 7, 8],
  \     'luis_match_priority': 1,
  \     'luis_match_score': 1000,
  \   },
  \ ], s:matcher.filter_candidates(cs1, { 'pattern': 'foobarbaz' }))

  call assert_equal([
  \   {
  \     'word': 'foobar',
  \     'luis_match_positions': [0, 3],
  \     'luis_match_priority': 0,
  \     'luis_match_score': 633,
  \   },
  \   {
  \     'word': 'foobarbaz',
  \     'luis_match_positions': [0, 3],
  \     'luis_match_priority': 1,
  \     'luis_match_score': 722,
  \   },
  \ ], s:matcher.filter_candidates(cs1, { 'pattern': 'fb' }))
  call assert_equal([
  \   {
  \     'word': 'foobarbaz',
  \     'luis_match_positions': [0, 3, 6],
  \     'luis_match_priority': 1,
  \     'luis_match_score': 533,
  \   },
  \ ], s:matcher.filter_candidates(cs1, { 'pattern': 'fbb' }))
endfunction

function! s:test_matcher_definition() abort
  call assert_true(luis#validate_matcher(s:matcher))
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
  \   'ui': CreateMockUI(),
  \   'source': CreateMockSource(),
  \   'matcher': CreateMockMatcher(),
  \   'comparer': comparer,
  \   'previewer': CreateMockPreviewer(),
  \   'hook': CreateMockHook(),
  \ }
  let context = { 'session': session }
  call assert_equal(
  \   [cs1[0], cs1[1], cs1[3], cs1[2]],
  \   s:matcher.sort_candidates(copy(cs1), context)
  \ )
  call assert_true(comparer_spies.compare_candidates.called())

  let [comparer, comparer_spies] = SpyDict(CreateMockComparer())
  let session = {
  \   'ui': CreateMockUI(),
  \   'source': CreateMockSource(),
  \   'matcher': CreateMockMatcher(),
  \   'comparer': comparer,
  \   'previewer': CreateMockPreviewer(),
  \   'hook': CreateMockHook(),
  \ }
  let context = { 'session': session }
  call assert_equal(
  \   [cs2[3], cs2[2], cs2[0], cs2[1]],
  \   s:matcher.sort_candidates(copy(cs2), context)
  \ )
  call assert_true(comparer_spies.compare_candidates.called())
endfunction
