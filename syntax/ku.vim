if exists('b:current_syntax')
  finish
endif

syntax case match

syntax match kuStatusLine /\%1l.*/
\            contains=kuSourcePrompt,kuSourceSeparator,kuSourceName
syntax match kuSourcePrompt /^Source/ contained nextgroup=kuSourceSeparator
syntax match kuSourceSeparator /: / contained nextgroup=kuSourceName
syntax match kuSourceName /[a-z/_-]\+/ contained

syntax match kuInputLine /\%2l.*/ contains=kuInputPrompt
syntax match kuInputPrompt /^>/ contained nextgroup=kuInputPattern
syntax match kuInputPattern /.*/ contained

highlight default link kuSourceName  Type
highlight default link kuSourcePrompt  Statement
highlight default link kuSourceSeparator  NONE

highlight default link kuInputPattern  NONE
highlight default link kuInputPrompt  Statement

" The following definitions are for <Plug>(ku-choose-action).
" See s:choose_action() in autoload/ku.vim for the details.
highlight default link kuChooseAction  NONE
highlight default link kuChooseCandidate  NONE
highlight default link kuChooseKey  SpecialKey
highlight default link kuChooseMessage  NONE
highlight default link kuChoosePrompt  kuSourcePrompt
highlight default link kuChooseSource  kuSourceName

let b:current_syntax = 'ku'
