if !exists('g:luis#matcher#default')
  let g:luis#matcher#default = exists('*matchfuzzypos')
  \                          ? g:luis#matcher#fuzzy#export
  \                          : g:luis#matcher#smart#export
endif
