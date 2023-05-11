function s:test_matcher_definition() abort
  let matcher = g:luis#matcher#default#export
  call assert_equal([], luis#internal#validate_matcher(matcher))
endfunction
