function s:test_filter_candidates() abort
  let matcher = g:luis#matcher#exact#export
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
  call Test(candidates, '', [
  \   { 'word': 'foo' },
  \   { 'word': 'foobar' },
  \   { 'word': 'foobarbaz' },
  \ ])
  call Test(candidates, 'foo', [
  \   { 'word': 'foo' },
  \   { 'word': 'foobar' },
  \   { 'word': 'foobarbaz' },
  \ ])
  call Test(candidates, 'bar', [
  \   { 'word': 'foobar' },
  \   { 'word': 'foobarbaz' },
  \ ])
  call Test(candidates, 'baz', [
  \   { 'word': 'foobarbaz' },
  \ ])
  call Test(candidates, 'qux', [])
  call Test(candidates, 'foobar', [
  \   { 'word': 'foobar' },
  \   { 'word': 'foobarbaz' },
  \ ])
  call Test(candidates, 'foobaz', [])
  call Test(candidates, 'foobarbaz', [
  \   { 'word': 'foobarbaz' },
  \ ])
  call Test(candidates, 'foobarqux', [])
  call Test(candidates, 'fb', [])
  call Test(candidates, 'fbb', [])
endfunction

function s:test_normalize_candidate() abort
  let matcher = g:luis#matcher#exact#export
  let Test = { candidate, index, args, expected ->
  \     matcher.normalize_candidate(copy(candidate), index, args)
  \ }

  let candidate = { 'word': 'foo' }
  let index = 0
  let args = {}
  call Test(candidate, index, args, candidate)
endfunction

function s:test_sort_candidates() abort
  let matcher = g:luis#matcher#exact#export
  let Test = { candidates, args, expected ->
  \   assert_equal(
  \     expected,
  \     matcher.sort_candidates(copy(candidates), args)
  \   )
  \ }

  let candidates = [
  \   { 'word': 'foobarbaz', 'luis_sort_priority': 0 },
  \   { 'word': 'foobar', 'luis_sort_priority': 0 },
  \   { 'word': 'FOOBAR', 'luis_sort_priority': 0 },
  \   { 'word': 'foo', 'luis_sort_priority': 0 },
  \ ]
  let args = {}
  call Test(candidates, args, [
  \   { 'word': 'FOOBAR', 'luis_sort_priority': 0 },
  \   { 'word': 'foo', 'luis_sort_priority': 0 },
  \   { 'word': 'foobar', 'luis_sort_priority': 0 },
  \   { 'word': 'foobarbaz', 'luis_sort_priority': 0 },
  \ ])

  let candidates = [
  \   { 'word': 'foobarbaz', 'luis_sort_priority': 1 },
  \   { 'word': 'foobar', 'luis_sort_priority': 0 },
  \   { 'word': 'FOOBAR', 'luis_sort_priority': 0 },
  \   { 'word': 'foo', 'luis_sort_priority': 1 },
  \ ]
  let args = {}
  call Test(candidates, args, [
  \   { 'word': 'FOOBAR', 'luis_sort_priority': 0 },
  \   { 'word': 'foobar', 'luis_sort_priority': 0 },
  \   { 'word': 'foo', 'luis_sort_priority': 1 },
  \   { 'word': 'foobarbaz', 'luis_sort_priority': 1 },
  \ ])
endfunction
