function s:test_filter_candidates() abort
  if !exists('*matchfuzzypos')
    return 'matchfuzzypos() function is required.'
  endif

  let matcher = g:luis#matcher#fuzzy#export
  let Test = { candidates, pattern ->
  \   matcher.filter_candidates(candidates, { 'pattern': pattern })
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

function s:test_matcher_definition() abort
  let matcher = g:luis#matcher#fuzzy#export
  call assert_equal([], luis#internal#validate_matcher(matcher))
endfunction

function s:test_normalize_candidate() abort
  let matcher = g:luis#matcher#fuzzy#export
  let Test = { candidate, index, context, expected ->
  \   assert_equal(
  \     expected, 
  \     matcher.normalize_candidate(copy(candidate), index, context)
  \   )
  \ }

  let candidate = { 'word': 'foo' }
  let index = 0
  let context = { '_positions': [[0]], '_scores': [100] }
  call Test(candidate, index, context, {
  \   'word': 'foo',
  \   'luis_match_pos': [0],
  \   'luis_match_score': 100
  \ })
endfunction

function s:test_sort_candidates() abort
  let matcher = g:luis#matcher#fuzzy#export
  let Test = { candidates, context, expected ->
  \   assert_equal(
  \     expected,
  \     matcher.sort_candidates(copy(candidates), context)
  \   )
  \ }

  let candidates = [
  \   { 'word': 'foobarbaz', 'luis_match_score': 189, 'luis_match_pos': [0, 1, 2], 'luis_sort_priority': 0 },
  \   { 'word': 'FOOBAR', 'luis_match_score': 192, 'luis_match_pos': [0, 1, 2], 'luis_sort_priority': 0 },
  \   { 'word': 'foobar', 'luis_match_score': 192, 'luis_match_pos': [0, 1, 2], 'luis_sort_priority': 0 },
  \   { 'word': 'foo', 'luis_match_score': 195, 'luis_match_pos': [0, 1, 2], 'luis_sort_priority': 0 },
  \ ]
  let context = {}
  call Test(candidates, context, [
  \   { 'word': 'FOOBAR', 'luis_match_score': 192, 'luis_match_pos': [0, 1, 2], 'luis_sort_priority': 0 },
  \   { 'word': 'foo', 'luis_match_score': 195, 'luis_match_pos': [0, 1, 2], 'luis_sort_priority': 0 },
  \   { 'word': 'foobar', 'luis_match_score': 192, 'luis_match_pos': [0, 1, 2], 'luis_sort_priority': 0 },
  \   { 'word': 'foobarbaz', 'luis_match_score': 189, 'luis_match_pos': [0, 1, 2], 'luis_sort_priority': 0 },
  \ ])

  let candidates = [
  \   { 'word': 'foobarbaz', 'luis_match_score': 189, 'luis_match_pos': [0, 1, 2], 'luis_sort_priority': 1 },
  \   { 'word': 'FOOBAR', 'luis_match_score': 192, 'luis_match_pos': [0, 1, 2], 'luis_sort_priority': 0 },
  \   { 'word': 'foobar', 'luis_match_score': 192, 'luis_match_pos': [0, 1, 2], 'luis_sort_priority': 0 },
  \   { 'word': 'foo', 'luis_match_score': 195, 'luis_match_pos': [0, 1, 2], 'luis_sort_priority': 1 },
  \ ]
  let context = {}
  call Test(candidates, context, [
  \   { 'word': 'FOOBAR', 'luis_match_score': 192, 'luis_match_pos': [0, 1, 2], 'luis_sort_priority': 0 },
  \   { 'word': 'foobar', 'luis_match_score': 192, 'luis_match_pos': [0, 1, 2], 'luis_sort_priority': 0 },
  \   { 'word': 'foo', 'luis_match_score': 195, 'luis_match_pos': [0, 1, 2], 'luis_sort_priority': 1 },
  \   { 'word': 'foobarbaz', 'luis_match_score': 189, 'luis_match_pos': [0, 1, 2], 'luis_sort_priority': 1 },
  \ ])
endfunction
