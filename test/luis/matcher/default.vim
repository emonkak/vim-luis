let s:matcher = luis#matcher#default#import()

function s:test_matcher_definition() abort
  call assert_equal([], luis#_validate_matcher(s:matcher))
endfunction
