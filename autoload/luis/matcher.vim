if !exists('g:luis#matcher#default')
  if exists('*matchfuzzypos')
    let g:luis#matcher#default = g:luis#matcher#fuzzy#export
  else
    let g:luis#matcher#default = g:luis#matcher#simple#export
  endif
endif
