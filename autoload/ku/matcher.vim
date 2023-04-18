if !exists('g:ku#matcher#default')
  if exists('*matchfuzzypos')
    let g:ku#matcher#default = g:ku#matcher#fuzzy#export
  else
    let g:ku#matcher#default = g:ku#matcher#simple#export
  endif
endif
