if !exists('g:luis_default_matcher')
  let g:luis_default_matcher = exists('*matchfuzzypos')
  \                          ? luis#matcher#fuzzy_native#import()
  \                          : luis#matcher#fuzzy#import()
endif

function! luis#matcher#default#import() abort
  return g:luis_default_matcher
endfunction
