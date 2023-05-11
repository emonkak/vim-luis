if !exists('g:luis#matcher#default#export')
  let g:luis#matcher#default#export = exists('*matchfuzzypos')
  \                                 ? g:luis#matcher#fuzzy#export
  \                                 : g:luis#matcher#smart#export
endif
