function s:test_filter_candidates() abort
  let matcher = g:luis#matcher#smart#export
  let Test = { expected, candidates, pattern ->
  \   assert_equal(
  \     expected,
  \     map(
  \       matcher.filter_candidates(candidates, { 'pattern': pattern }),
  \      '{ "word": v:val.word }'
  \     )
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
  call Test([
  \   { 'word': 'foobarbaz' },
  \ ], candidates, 'foobaz')
  call Test([
  \   { 'word': 'foobarbaz' },
  \ ], candidates, 'foobarbaz')
  call Test([], candidates, 'foobarqux')
  call Test([
  \   { 'word': 'foobar' },
  \   { 'word': 'foobarbaz' },
  \ ], candidates, 'fb')
  call Test([
  \   { 'word': 'foobarbaz' },
  \ ], candidates, 'fbb')
endfunction

function s:test_matcher_definition() abort
  let matcher = g:luis#matcher#smart#export
  call assert_equal([], luis#internal#validate_matcher(matcher))
endfunction

function s:test_normalize_candidate() abort
  let matcher = g:luis#matcher#fuzzy#export
  let Test = { expected, candidate, index, context ->
  \   assert_equal(
  \     expected,
  \     matcher.normalize_candidate(copy(candidate), index, context)
  \   )
  \ }

  let candidate = { 'word': 'foo' }
  let index = 0
  let context = { '_positions': [[0]], '_scores': [100] }
  call Test({
  \   'word': 'foo',
  \   'luis_match_pos': [0],
  \   'luis_match_score': 100,
  \ }, candidate, index, context)
endfunction

function s:test_sort_candidates() abort
  let matcher = g:luis#matcher#smart#export
  let Test = { expected, candidates, context ->
  \   assert_equal(
  \     expected,
  \     matcher.sort_candidates(copy(candidates), context)
  \   )
  \ }

  let candidates = [
  \   { 'word': 'foobarbaz', 'luis_match_score': 0.933333, 'luis_sort_priority': 0 },
  \   { 'word': 'foobar', 'luis_match_score': 0.95, 'luis_sort_priority': 0 },
  \   { 'word': 'foo', 'luis_match_score': 1.0, 'luis_sort_priority': 0 },
  \   { 'word': 'FOOBAR', 'luis_match_score': 0.95, 'luis_sort_priority': 0 },
  \ ]
  let context = {}
  call Test([
  \   { 'word': 'foo', 'luis_match_score': 1.0, 'luis_sort_priority': 0 },
  \   { 'word': 'FOOBAR', 'luis_match_score': 0.95, 'luis_sort_priority': 0 },
  \   { 'word': 'foobar', 'luis_match_score': 0.95, 'luis_sort_priority': 0 },
  \   { 'word': 'foobarbaz', 'luis_match_score': 0.933333, 'luis_sort_priority': 0 },
  \ ], candidates, context)

  let candidates = [
  \   { 'word': 'foobarbaz', 'luis_match_score': 0.933333, 'luis_sort_priority': 1 },
  \   { 'word': 'FOOBAR', 'luis_match_score': 0.95, 'luis_sort_priority': 0 },
  \   { 'word': 'foobar', 'luis_match_score': 0.95, 'luis_sort_priority': 0 },
  \   { 'word': 'foo', 'luis_match_score': 1.0, 'luis_sort_priority': 1 },
  \ ]
  let context = {}
  call Test([
  \   { 'word': 'FOOBAR', 'luis_match_score': 0.95, 'luis_sort_priority': 0 },
  \   { 'word': 'foobar', 'luis_match_score': 0.95, 'luis_sort_priority': 0 },
  \   { 'word': 'foo', 'luis_match_score': 1.0, 'luis_sort_priority': 1 },
  \   { 'word': 'foobarbaz', 'luis_match_score': 0.933333, 'luis_sort_priority': 1 },
  \ ], candidates, context)
endfunction
