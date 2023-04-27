function s:test_filter_candidates() abort
  let matcher = g:luis#matcher#smart#export
  let Test = { candidates, pattern, expected ->
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
  call Test(candidates, 'foobaz', [
  \   { 'word': 'foobarbaz' },
  \ ])
  call Test(candidates, 'foobarbaz', [
  \   { 'word': 'foobarbaz' },
  \ ])
  call Test(candidates, 'foobarqux', [])
  call Test(candidates, 'fb', [
  \   { 'word': 'foobar' },
  \   { 'word': 'foobarbaz' },
  \ ])
  call Test(candidates, 'fbb', [
  \   { 'word': 'foobarbaz' },
  \ ])
endfunction

function s:test_normalize_candidate() abort
  let matcher = g:luis#matcher#fuzzy#export
  let Test = { candidate, index, args, expected ->
  \   assert_equal(
  \     expected,
  \     matcher.normalize_candidate(copy(candidate), index, args)
  \   )
  \ }

  let candidate = { 'word': 'foo' }
  let index = 0
  let args = { '_positions': [[0]], '_scores': [100] }
  call Test(candidate, index, args, {
  \   'word': 'foo',
  \   'luis_fuzzy_pos': [0],
  \   'luis_fuzzy_score': 100,
  \ })
endfunction

function s:test_sort_candidates() abort
  let matcher = g:luis#matcher#smart#export
  let Test = { candidates, args, expected ->
  \   assert_equal(
  \     expected,
  \     matcher.sort_candidates(copy(candidates), args)
  \   )
  \ }

  let candidates = [
  \   { 'word': 'foobarbaz', 'luis_smart_score': 0.933333, 'luis_sort_priority': 0 },
  \   { 'word': 'foobar', 'luis_smart_score': 0.95, 'luis_sort_priority': 0 },
  \   { 'word': 'foo', 'luis_smart_score': 1.0, 'luis_sort_priority': 0 },
  \   { 'word': 'FOOBAR', 'luis_smart_score': 0.95, 'luis_sort_priority': 0 },
  \ ]
  let args = {}
  call Test(candidates, args, [
  \   { 'word': 'foo', 'luis_smart_score': 1.0, 'luis_sort_priority': 0 },
  \   { 'word': 'FOOBAR', 'luis_smart_score': 0.95, 'luis_sort_priority': 0 },
  \   { 'word': 'foobar', 'luis_smart_score': 0.95, 'luis_sort_priority': 0 },
  \   { 'word': 'foobarbaz', 'luis_smart_score': 0.933333, 'luis_sort_priority': 0 },
  \ ])

  let candidates = [
  \   { 'word': 'foobarbaz', 'luis_smart_score': 0.933333, 'luis_sort_priority': 1 },
  \   { 'word': 'FOOBAR', 'luis_smart_score': 0.95, 'luis_sort_priority': 0 },
  \   { 'word': 'foobar', 'luis_smart_score': 0.95, 'luis_sort_priority': 0 },
  \   { 'word': 'foo', 'luis_smart_score': 1.0, 'luis_sort_priority': 1 },
  \ ]
  let args = {}
  call Test(candidates, args, [
  \   { 'word': 'FOOBAR', 'luis_smart_score': 0.95, 'luis_sort_priority': 0 },
  \   { 'word': 'foobar', 'luis_smart_score': 0.95, 'luis_sort_priority': 0 },
  \   { 'word': 'foo', 'luis_smart_score': 1.0, 'luis_sort_priority': 1 },
  \   { 'word': 'foobarbaz', 'luis_smart_score': 0.933333, 'luis_sort_priority': 1 },
  \ ])
endfunction
