function s:test_filter_candidates() abort
  let matcher = g:luis#matcher#exact#export
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
  call Test([
  \   { 'word': 'foo' },
  \   { 'word': 'foobar' },
  \   { 'word': 'foobarbaz' },
  \ ], candidates, '')
  call Test([
  \   { 'word': 'foo' },
  \   { 'word': 'foobar' },
  \   { 'word': 'foobarbaz' },
  \ ], candidates, 'foo')
  call Test([
  \   { 'word': 'foobar' },
  \   { 'word': 'foobarbaz' },
  \ ], candidates, 'bar')
  call Test([
  \   { 'word': 'foobarbaz' },
  \ ], candidates, 'baz')
  call Test([], candidates, 'qux')
  call Test([
  \   { 'word': 'foobar' },
  \   { 'word': 'foobarbaz' },
  \ ], candidates, 'foobar')
  call Test([], candidates, 'foobaz')
  call Test([
  \   { 'word': 'foobarbaz' },
  \ ], candidates, 'foobarbaz')
  call Test([], candidates, 'foobarqux')
  call Test([], candidates, 'fb')
  call Test([], candidates, 'fbb')
endfunction

function s:test_normalize_candidate() abort
  let matcher = g:luis#matcher#exact#export
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
  let matcher = g:luis#matcher#exact#export
  let Test = { expected, candidates, context ->
  \   assert_equal(
  \     expected,
  \     matcher.sort_candidates(copy(candidates), context)
  \   )
  \ }

  let candidates = [
  \   { 'word': 'foobarbaz', 'luis_sort_priority': 0 },
  \   { 'word': 'foobar', 'luis_sort_priority': 0 },
  \   { 'word': 'FOOBAR', 'luis_sort_priority': 0 },
  \   { 'word': 'foo', 'luis_sort_priority': 0 },
  \ ]
  let context = {}
  call Test([
  \   { 'word': 'FOOBAR', 'luis_sort_priority': 0 },
  \   { 'word': 'foo', 'luis_sort_priority': 0 },
  \   { 'word': 'foobar', 'luis_sort_priority': 0 },
  \   { 'word': 'foobarbaz', 'luis_sort_priority': 0 },
  \ ], candidates, context)

  let candidates = [
  \   { 'word': 'foobarbaz', 'luis_sort_priority': 1 },
  \   { 'word': 'foobar', 'luis_sort_priority': 0 },
  \   { 'word': 'FOOBAR', 'luis_sort_priority': 0 },
  \   { 'word': 'foo', 'luis_sort_priority': 1 },
  \ ]
  let context = {}
  call Test([
  \   { 'word': 'FOOBAR', 'luis_sort_priority': 0 },
  \   { 'word': 'foobar', 'luis_sort_priority': 0 },
  \   { 'word': 'foo', 'luis_sort_priority': 1 },
  \   { 'word': 'foobarbaz', 'luis_sort_priority': 1 },
  \ ], candidates, context)
endfunction
