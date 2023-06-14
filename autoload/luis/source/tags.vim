function! luis#source#tags#new(window) abort
  let source = copy(s:Source)
  let source.window = a:window
  return source
endfunction

let s:Source = {
\   'name': 'tags',
\   'default_kind': luis#kind#tag#import(),
\   'matcher': luis#matcher#through#import(),
\ }

function! s:Source.gather_candidates(context) abort dict
  let original_window = win_getid()
  try
    noautocmd call win_gotoid(self.window)
    return map(
    \   getcompletion(a:context.pattern, 'tag'),
    \   '{ "word": v:val }'
    \ )
  finally
    noautocmd call win_gotoid(original_window)
  endtry
endfunction
