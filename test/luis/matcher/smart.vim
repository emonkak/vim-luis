let s:matcher = luis#matcher#smart#import()

function s:test_filter_candidates() abort
  let cs = [
  \   { 'word': 'foo' },
  \   { 'word': 'foobar' },
  \   { 'word': 'foobarbaz' },
  \ ]

  call assert_equal([
  \   {
  \     'word': 'foo',
  \     'luis_match_score': 900,
  \     'luis_match_start_pos': -1,
  \     'luis_match_end_pos': -1,
  \   },
  \   {
  \     'word': 'foobar',
  \     'luis_match_score': 900,
  \     'luis_match_start_pos': -1,
  \     'luis_match_end_pos': -1,
  \   },
  \   {
  \     'word': 'foobarbaz',
  \     'luis_match_score': 900,
  \     'luis_match_start_pos': -1,
  \     'luis_match_end_pos': -1,
  \   },
  \ ], s:matcher.filter_candidates(cs, { 'pattern': '' }))
  call assert_equal([
  \   {
  \     'word': 'foo',
  \     'luis_match_score': 1000,
  \     'luis_match_start_pos': 0,
  \     'luis_match_end_pos': 2,
  \   },
  \   {
  \     'word': 'foobar',
  \     'luis_match_score': 950,
  \     'luis_match_start_pos': 0,
  \     'luis_match_end_pos': 2,
  \   },
  \   {
  \     'word': 'foobarbaz',
  \     'luis_match_score': 933,
  \     'luis_match_start_pos': 0,
  \     'luis_match_end_pos': 2,
  \   },
  \ ], s:matcher.filter_candidates(cs, { 'pattern': 'foo' }))
  call assert_equal([
  \   {
  \     'word': 'foobar',
  \     'luis_match_score': 500,
  \     'luis_match_start_pos': 3,
  \     'luis_match_end_pos': 5,
  \   },
  \   {
  \     'word': 'foobarbaz',
  \     'luis_match_score': 633,
  \     'luis_match_start_pos': 3,
  \     'luis_match_end_pos': 5,
  \   },
  \ ], s:matcher.filter_candidates(cs, { 'pattern': 'bar' }))
  call assert_equal([
  \   {
  \     'word': 'foobarbaz',
  \     'luis_match_score': 333,
  \     'luis_match_start_pos': 6,
  \     'luis_match_end_pos': 8,
  \   },
  \ ], s:matcher.filter_candidates(cs, { 'pattern': 'baz' }))
  call assert_equal([], s:matcher.filter_candidates(cs, { 'pattern': 'qux' }))

  call assert_equal([
  \   {
  \     'word': 'foobar',
  \     'luis_match_score': 1000,
  \     'luis_match_start_pos': 0,
  \     'luis_match_end_pos': 5,
  \   },
  \   {
  \     'word': 'foobarbaz',
  \     'luis_match_score': 967,
  \     'luis_match_start_pos': 0,
  \     'luis_match_end_pos': 5,
  \   },
  \ ], s:matcher.filter_candidates(cs, { 'pattern': 'foobar' }))
  call assert_equal([
  \   {
  \     'word': 'foobarbaz',
  \     'luis_match_score': 667,
  \     'luis_match_start_pos': 0,
  \     'luis_match_end_pos': 8,
  \   },
  \ ], s:matcher.filter_candidates(cs, { 'pattern': 'foobaz' }))
  call assert_equal(
  \   [],
  \   s:matcher.filter_candidates(cs, { 'pattern': 'foobarbar' })
  \ )
  call assert_equal([
  \   {
  \     'word': 'foobarbaz',
  \     'luis_match_score': 1000,
  \     'luis_match_start_pos': 0,
  \     'luis_match_end_pos': 8,
  \   },
  \ ], s:matcher.filter_candidates(cs, { 'pattern': 'foobarbaz' }))

  call assert_equal([
  \   {
  \     'word': 'foobar',
  \     'luis_match_score': 633,
  \     'luis_match_start_pos': 0,
  \     'luis_match_end_pos': 3,
  \   },
  \   {
  \     'word': 'foobarbaz',
  \     'luis_match_score': 722,
  \     'luis_match_start_pos': 0,
  \     'luis_match_end_pos': 3,
  \   },
  \ ], s:matcher.filter_candidates(cs, { 'pattern': 'fb' }))
  call assert_equal([
  \   {
  \     'word': 'foobarbaz',
  \     'luis_match_score': 533,
  \     'luis_match_start_pos': 0,
  \     'luis_match_end_pos': 6,
  \   },
  \ ], s:matcher.filter_candidates(cs, { 'pattern': 'fbb' }))
endfunction

function s:test_matcher_definition() abort
  call assert_equal([], luis#_validate_matcher(s:matcher))
endfunction

function s:test_normalize_candidate() abort
  let candidate = { 'word': 'foo' }
  let index = 0
  let context = {}
  call assert_equal(
  \    { 'word': 'foo', 'luis_sort_priority': 0 },
  \    s:matcher.normalize_candidate(copy(candidate), index, context)
  \ )

  let candidate = { 'word': 'foo', 'luis_sort_priority': 1 }
  let index = 0
  let context = {}
  call assert_equal(
  \    { 'word': 'foo', 'luis_sort_priority': 1 },
  \    s:matcher.normalize_candidate(copy(candidate), index, context)
  \ )
endfunction

function s:test_sort_candidates() abort
  let cs = [
  \   {
  \     'word': '/BIN',
  \     'luis_match_score': 950,
  \     'luis_match_start_pos': 0,
  \     'luis_match_end_pos': 1,
  \     'luis_sort_priority': 0,
  \   },
  \   {
  \     'word': '/bin',
  \     'luis_match_score': 950,
  \     'luis_match_start_pos': 0,
  \     'luis_match_end_pos': 1,
  \     'luis_sort_priority': 0,
  \   },
  \   {
  \     'word': '/lib',
  \     'luis_match_score': 500,
  \     'luis_match_start_pos': 0,
  \     'luis_match_end_pos': 3,
  \     'luis_sort_priority': 0,
  \   },
  \   {
  \     'word': '/sbin',
  \     'luis_match_score': 760,
  \     'luis_match_start_pos': 0,
  \     'luis_match_end_pos': 2,
  \     'luis_sort_priority': 0,
  \   },
  \ ]
  let context = {}
  call assert_equal(
  \   [cs[0], cs[1], cs[3], cs[2]],
  \   s:matcher.sort_candidates(cs, context)
  \ )

  let cs = [
  \   {
  \     'word': '/BIN',
  \     'luis_match_score': 950,
  \     'luis_match_start_pos': 0,
  \     'luis_match_end_pos': 1,
  \     'luis_sort_priority': 1,
  \   },
  \   {
  \     'word': '/bin',
  \     'luis_match_score': 950,
  \     'luis_match_start_pos': 0,
  \     'luis_match_end_pos': 1,
  \     'luis_sort_priority': 1,
  \   },
  \   {
  \     'word': '/lib',
  \     'luis_match_score': 500,
  \     'luis_match_start_pos': 0,
  \     'luis_match_end_pos': 3,
  \     'luis_sort_priority': 0,
  \   },
  \   {
  \     'word': '/sbin',
  \     'luis_match_score': 760,
  \     'luis_match_start_pos': 0,
  \     'luis_match_end_pos': 2,
  \     'luis_sort_priority': 0,
  \   },
  \ ]
  let context = {}
  call assert_equal(
  \   [cs[3], cs[2], cs[0], cs[1]],
  \   s:matcher.sort_candidates(cs, context)
  \ )
endfunction
