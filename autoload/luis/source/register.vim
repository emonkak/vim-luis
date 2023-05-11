let s:REGISTER_CHARS = '"0123456789-abcdefghijklmnopqrstuvwxyz:.%#=*+/'

let s:REGISTER_TYPES = {
\   'v': 'c',
\   'V': 'l',
\   "\<C-v>": 'b',
\ }

function! luis#source#register#new() abort
  let source = copy(s:Source)
  let source._cached_candidates = []
  return source
endfunction

let s:Source = {
\   'name': 'register',
\   'default_kind': g:luis#kind#register#export,
\   'matcher': g:luis#matcher#default#export,
\ }

function! s:Source.gather_candidates(context) abort dict
  return self._cached_candidates
endfunction

function! s:Source.on_source_enter() abort dict
  let candidates = []
  for i in range(len(s:REGISTER_CHARS))
    let name = s:REGISTER_CHARS[i]
    let contents = getreg(name, 1, 1)
    if empty(contents) || contents[0] == ''
      continue
    endif
    call add(candidates, {
    \   'word': '"' . name,
    \   'menu': contents[0],
    \   'kind': get(s:REGISTER_TYPES, getregtype(name)[0], ''),
    \   'user_data': {
    \     'register_name': name,
    \   },
    \   'luis_sort_priority': char2nr(name),
    \ })
  endfor
  let self._cached_candidates = candidates
endfunction
