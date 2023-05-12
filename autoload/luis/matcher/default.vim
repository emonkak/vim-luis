if !exists('g:luis_default_matcher')
  let g:luis_default_matcher = exists('*matchfuzzypos')
  \                          ? luis#matcher#fuzzy#import()
  \                          : luis#matcher#smart#import()
endif

function! luis#matcher#default#import() abort
  return g:luis_default_matcher
endfunction
