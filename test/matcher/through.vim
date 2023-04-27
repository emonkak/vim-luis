function s:test_filter_candidates() abort
  let matcher = g:luis#matcher#through#export
  let Test = { candidates, pattern, expected ->
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
  call Test(candidates, '', candidates)
  call Test(candidates, 'foo', candidates)
  call Test(candidates, 'bar', candidates)
  call Test(candidates, 'baz', candidates)
  call Test(candidates, 'qux', candidates)
endfunction

function s:test_normalize_candidate() abort
  let matcher = g:luis#matcher#through#export
  let Test = { candidate, index, args, expected ->
  \   assert_equal(
  \     expected,
  \     matcher.normalize_candidate(copy(candidate), index, args)
  \   )
  \ }

  let candidate = { 'word': 'foo' }
  let index = 0
  let args = {}
  call Test(candidate, index, args, candidate)
endfunction

function s:test_sort_candidates() abort
  let matcher = g:luis#matcher#through#export
  let Test = { candidate, args, expected ->
  \   assert_equal(
  \     expected,
  \     matcher.sort_candidates(copy(candidate), args)
  \   )
  \ }

  let candidates = [
  \   { 'word': 'foo' },
  \   { 'word': 'foobar' },
  \   { 'word': 'foobarbaz' },
  \ ]
  let args = {}
  call Test(candidates, args, candidates)
endfunction
