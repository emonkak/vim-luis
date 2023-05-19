let s:matcher = luis#matcher#exact#import()

function s:test_filter_candidates() abort
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
  call assert_equal(
  \   [],
  \   s:matcher.filter_candidates(cs, { 'pattern': 'foobaz' })
  \ )
  call assert_equal(
  \   [],
  \   s:matcher.filter_candidates(cs, { 'pattern': 'foobarbar' })
  \ )
  call assert_equal([
  \   { 'word': 'foobarbaz' },
  \ ], s:matcher.filter_candidates(cs, { 'pattern': 'foobarbaz' }))
  call assert_equal([], s:matcher.filter_candidates(cs, { 'pattern': 'fb' }))
  call assert_equal([], s:matcher.filter_candidates(cs, { 'pattern': 'fbb' }))
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
  \   { 'word': 'foobarbaz', 'luis_sort_priority': 0 },
  \   { 'word': 'foobar', 'luis_sort_priority': 0 },
  \   { 'word': 'FOOBAR', 'luis_sort_priority': 0 },
  \   { 'word': 'foo', 'luis_sort_priority': 0 },
  \ ]
  let context = {}
  call assert_equal([
  \   { 'word': 'FOOBAR', 'luis_sort_priority': 0 },
  \   { 'word': 'foo', 'luis_sort_priority': 0 },
  \   { 'word': 'foobar', 'luis_sort_priority': 0 },
  \   { 'word': 'foobarbaz', 'luis_sort_priority': 0 },
  \ ], s:matcher.sort_candidates(cs, context))

  let cs = [
  \   { 'word': 'foobarbaz', 'luis_sort_priority': 1 },
  \   { 'word': 'foobar', 'luis_sort_priority': 0 },
  \   { 'word': 'FOOBAR', 'luis_sort_priority': 0 },
  \   { 'word': 'foo', 'luis_sort_priority': 1 },
  \ ]
  call assert_equal([
  \   { 'word': 'FOOBAR', 'luis_sort_priority': 0 },
  \   { 'word': 'foobar', 'luis_sort_priority': 0 },
  \   { 'word': 'foo', 'luis_sort_priority': 1 },
  \   { 'word': 'foobarbaz', 'luis_sort_priority': 1 },
  \ ], s:matcher.sort_candidates(cs, context))
endfunction
