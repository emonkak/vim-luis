let s:REGISTER_CHARS = '"0123456789-abcdefghijklmnopqrstuvwxyz:.%#=*+/'

let s:REGISTER_TYPES = {
\   'v': 'c',
\   'V': 'l',
\   "\<C-v>": 'b',
\ }

function! luis#source#register#new() abort
  let source = copy(s:Source)
  let source.cached_candidates = []
  return source
endfunction

let s:Source = {
\   'name': 'register',
\   'default_kind': luis#kind#register#import(),
\ }

function! s:Source.gather_candidates(context) abort dict
  return self.cached_candidates
endfunction

function! s:Source.on_source_enter(context) abort dict
  let candidates = []
  for i in range(len(s:REGISTER_CHARS))
    let name = s:REGISTER_CHARS[i]
    let contents = getreg(name, 1, 1)
    if empty(contents) || contents[0] == ''
      continue
    endif
    call add(candidates, {
    \   'word': contents[0],
    \   'menu': '"' . name,
    \   'kind': get(s:REGISTER_TYPES, getregtype(name)[0], ''),
    \   'dup': 1,
    \   'user_data': {
    \     'register_name': name,
    \     'preview_lines': contents,
    \   },
    \   'luis_sort_priority': -char2nr(name),
    \ })
  endfor
  let self.cached_candidates = candidates
endfunction
