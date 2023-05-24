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
  call assert_equal(1, luis#validations#validate_matcher(s:matcher))
endfunction

function! s:test_normalize_candidate() abort
  let candidate = { 'word': 'foo' }
  let index = 0
  let context = { '_match_positions': [[0]], '_match_scores': [100] }
  call assert_equal({
  \   'word': 'foo',
  \   'luis_match_positions': [0],
  \   'luis_match_score': 100,
  \   'luis_sort_priority': 0,
  \ }, s:matcher.normalize_candidate(copy(candidate), index, context))

  let candidate = { 'word': 'foo', 'luis_sort_priority': 1 }
  let index = 0
  let context = { '_match_positions': [[0]], '_match_scores': [100] }
  call assert_equal({
  \   'word': 'foo',
  \   'luis_match_positions': [0],
  \   'luis_match_score': 100,
  \   'luis_sort_priority': 1,
  \ }, s:matcher.normalize_candidate(copy(candidate), index, context))
endfunction

function! s:test_sort_candidates() abort
  let cs = [
  \   { 'word': 'foobarbaz', 'luis_match_score': 189, 'luis_match_positions': [0, 1, 2], 'luis_sort_priority': 0 },
  \   { 'word': 'FOOBAR', 'luis_match_score': 192, 'luis_match_positions': [0, 1, 2], 'luis_sort_priority': 0 },
  \   { 'word': 'foobar', 'luis_match_score': 192, 'luis_match_positions': [0, 1, 2], 'luis_sort_priority': 0 },
  \   { 'word': 'foo', 'luis_match_score': 195, 'luis_match_positions': [0, 1, 2], 'luis_sort_priority': 0 },
  \ ]
  let context = {}
  call assert_equal([
  \   { 'word': 'FOOBAR', 'luis_match_score': 192, 'luis_match_positions': [0, 1, 2], 'luis_sort_priority': 0 },
  \   { 'word': 'foo', 'luis_match_score': 195, 'luis_match_positions': [0, 1, 2], 'luis_sort_priority': 0 },
  \   { 'word': 'foobar', 'luis_match_score': 192, 'luis_match_positions': [0, 1, 2], 'luis_sort_priority': 0 },
  \   { 'word': 'foobarbaz', 'luis_match_score': 189, 'luis_match_positions': [0, 1, 2], 'luis_sort_priority': 0 },
  \ ], s:matcher.sort_candidates(copy(cs), context))

  let cs = [
  \   { 'word': 'foobarbaz', 'luis_match_score': 189, 'luis_match_positions': [0, 1, 2], 'luis_sort_priority': 1 },
  \   { 'word': 'FOOBAR', 'luis_match_score': 192, 'luis_match_positions': [0, 1, 2], 'luis_sort_priority': 0 },
  \   { 'word': 'foobar', 'luis_match_score': 192, 'luis_match_positions': [0, 1, 2], 'luis_sort_priority': 0 },
  \   { 'word': 'foo', 'luis_match_score': 195, 'luis_match_positions': [0, 1, 2], 'luis_sort_priority': 1 },
  \ ]
  let context = {}
  call assert_equal([
  \   { 'word': 'FOOBAR', 'luis_match_score': 192, 'luis_match_positions': [0, 1, 2], 'luis_sort_priority': 0 },
  \   { 'word': 'foobar', 'luis_match_score': 192, 'luis_match_positions': [0, 1, 2], 'luis_sort_priority': 0 },
  \   { 'word': 'foo', 'luis_match_score': 195, 'luis_match_positions': [0, 1, 2], 'luis_sort_priority': 1 },
  \   { 'word': 'foobarbaz', 'luis_match_score': 189, 'luis_match_positions': [0, 1, 2], 'luis_sort_priority': 1 },
  \ ], s:matcher.sort_candidates(copy(cs), context))
endfunction
