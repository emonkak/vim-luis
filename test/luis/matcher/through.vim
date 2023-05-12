let s:matcher = luis#matcher#through#import()

function s:test_filter_candidates() abort
  let cs = [
  \   { 'word': 'foo' },
  \   { 'word': 'foobar' },
  \   { 'word': 'foobarbaz' },
  \ ]
  call assert_equal(cs, s:matcher.filter_candidates(cs, { 'pattern': '' }))
  call assert_equal(cs, s:matcher.filter_candidates(cs, { 'pattern': 'foo' }))
  call assert_equal(cs, s:matcher.filter_candidates(cs, { 'pattern': 'bar' }))
  call assert_equal(cs, s:matcher.filter_candidates(cs, { 'pattern': 'baz' }))
  call assert_equal(cs, s:matcher.filter_candidates(cs, { 'pattern': 'qux' }))
endfunction

function s:test_matcher_definition() abort
  call assert_equal([], luis#_validate_matcher(s:matcher))
endfunction

function s:test_normalize_candidate() abort
  let candidate = { 'word': 'foo' }
  let index = 0
  let context = {}
  call assert_equal(
  \   candidate,
  \   s:matcher.normalize_candidate(copy(candidate), index, context)
  \ )
endfunction

function s:test_sort_candidates() abort
  let cs = [
  \   { 'word': 'foo' },
  \   { 'word': 'foobar' },
  \   { 'word': 'foobarbaz' },
  \ ]
  let context = {}
  call assert_equal(
  \   cs,
  \   s:matcher.sort_candidates(copy(cs), context)
  \ )
endfunction
