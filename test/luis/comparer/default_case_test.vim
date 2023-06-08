let s:comparer = luis#comparer#default_case#import()

function! s:test_compare_candidates() abort
  call assert_equal(
  \   { 'word': 'A', 'luis_sort_priority': 0 },
  \   s:comparer.normalize_candidate({ 'word': 'A' }, 0, {})
  \ )
  call assert_equal(
  \   { 'word': 'A', 'luis_sort_priority': 1 },
  \   s:comparer.normalize_candidate(
  \     { 'word': 'A', 'luis_sort_priority': 1 },
  \     0,
  \     {}
  \   )
  \ )

  call assert_equal(
  \   0,
  \   s:comparer.compare_candidates(
  \     { 'word': 'A', 'luis_sort_priority': 0 },
  \     { 'word': 'A', 'luis_sort_priority': 0 }
  \   )
  \ )
  call assert_equal(
  \   -1,
  \   s:comparer.compare_candidates(
  \     { 'word': 'A', 'luis_sort_priority': 0 },
  \     { 'word': 'B', 'luis_sort_priority': 0 }
  \   )
  \ )
  call assert_equal(
  \   1,
  \   s:comparer.compare_candidates(
  \     { 'word': 'B', 'luis_sort_priority': 0 },
  \     { 'word': 'A', 'luis_sort_priority': 0 }
  \   )
  \ )
  call assert_equal(
  \   -1,
  \   s:comparer.compare_candidates(
  \     { 'word': 'A', 'luis_sort_priority': 1 },
  \     { 'word': 'A', 'luis_sort_priority': 0 }
  \   )
  \ )
  call assert_equal(
  \   -1,
  \   s:comparer.compare_candidates(
  \     { 'word': 'B', 'luis_sort_priority': 1 },
  \     { 'word': 'A', 'luis_sort_priority': 0 }
  \   )
  \ )
  call assert_equal(
  \   1,
  \   s:comparer.compare_candidates(
  \     { 'word': 'A', 'luis_sort_priority': 0 },
  \     { 'word': 'A', 'luis_sort_priority': 1 }
  \   )
  \ )
  call assert_equal(
  \   1,
  \   s:comparer.compare_candidates(
  \     { 'word': 'B', 'luis_sort_priority': 0 },
  \     { 'word': 'A', 'luis_sort_priority': 1 }
  \   )
  \ )
endfunction
