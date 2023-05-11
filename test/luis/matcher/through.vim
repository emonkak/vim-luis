function s:test_filter_candidates() abort
  let matcher = g:luis#matcher#through#export
  let Test = { expected, candidates, pattern ->
  \   assert_equal(
  \     expected,
  \     matcher.filter_candidates(copy(candidates), { 'pattern': pattern })
  \   )
  \ }

  let candidates = [
  \   { 'word': 'foo' },
  \   { 'word': 'foobar' },
  \   { 'word': 'foobarbaz' },
  \ ]
  call Test(candidates, candidates, '')
  call Test(candidates, candidates, 'foo')
  call Test(candidates, candidates, 'bar')
  call Test(candidates, candidates, 'baz')
  call Test(candidates, candidates, 'qux')
endfunction

function s:test_matcher_definition() abort
  let matcher = g:luis#matcher#through#export
  call assert_equal([], luis#internal#validate_matcher(matcher))
endfunction

function s:test_normalize_candidate() abort
  let matcher = g:luis#matcher#through#export
  let Test = { expected, candidate, index, context ->
  \   assert_equal(
  \     expected,
  \     matcher.normalize_candidate(copy(candidate), index, context)
  \   )
  \ }

  let candidate = { 'word': 'foo' }
  let index = 0
  let context = {}
  call Test(candidate, candidate, index, context)
endfunction

function s:test_sort_candidates() abort
  let matcher = g:luis#matcher#through#export
  let Test = { expected, candidate, context ->
  \   assert_equal(
  \     expected,
  \     matcher.sort_candidates(copy(candidate), context)
  \   )
  \ }

  let candidates = [
  \   { 'word': 'foo' },
  \   { 'word': 'foobar' },
  \   { 'word': 'foobarbaz' },
  \ ]
  let context = {}
  call Test(candidates, candidates, context)
endfunction
