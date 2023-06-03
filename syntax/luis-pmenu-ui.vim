if exists('b:current_syntax')
  finish
endif

syntax case match

syntax match luisStatusLine /\%1l.*/
\            contains=luisSourcePrompt
syntax match luisSourcePrompt /^Source/ contained nextgroup=luisSourceSeparator
syntax match luisSourceSeparator /: / contained nextgroup=luisSourceName
syntax match luisSourceName /\h[A-Za-z/_-]*/ contained

syntax match luisInputLine /\%2l.*/ contains=luisInputPrompt
syntax match luisInputPrompt /^>/ contained nextgroup=luisInputPattern
syntax match luisInputPattern /.*/ contained

highlight default link luisSourceName  Type
highlight default link luisSourcePrompt  Statement
highlight default link luisSourceSeparator  NONE

highlight default link luisInputPattern  NONE
highlight default link luisInputPrompt  Statement

" The following definitions are for <Plug>(luis-choose-action).
" See s:choose_action() in autoload/luis.vim for the details.
highlight default link luisChooseAction  NONE
highlight default link luisChooseCandidate  NONE
highlight default link luisChooseKey  SpecialKey
highlight default link luisChooseMessage  NONE
highlight default link luisChoosePrompt  Statement
highlight default link luisChooseKind  Type

let b:current_syntax = 'luis-pmenu'
