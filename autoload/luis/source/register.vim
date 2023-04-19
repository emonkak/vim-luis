let s:AVAILABLE_REGISTERS = '"'
\                         . '0123456789'
\                         . '-'
\                         . 'abcdefghijklmnopqrstuvwxyz'
\                         . 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
\                         . ':.%'
\                         . '#'
\                         . '='
\                         . '*+'
\                         . '/'

function! luis#source#register#new() abort
  let source = copy(s:Source)
  let source._cached_candidates = []
  return source
endfunction

let s:Source = {
\   'name': 'register',
\   'default_kind': g:luis#kind#register#export,
\   'matcher': g:luis#matcher#default,
\ }

function! s:Source.gather_candidates(pattern) abort dict
  return self._cached_candidates
endfunction

function! s:Source.on_source_enter() abort dict
  let candidates = []
  for i in range(len(s:AVAILABLE_REGISTERS))
    let register = s:AVAILABLE_REGISTERS[i]
    let reginfo = getreginfo(register)
    if empty(reginfo) || empty(reginfo.regcontents)
      continue
    endif
    call add(candidates, {
    \   'word': reginfo.regcontents[0],
    \   'menu': 'register ' . register,
    \   'dup': 1,
    \   'user_data': {
    \     'register_name': register,
    \   },
    \   'luis_sort_priority': i,
    \ })
  endfor
  let self._cached_candidates = candidates
endfunction
