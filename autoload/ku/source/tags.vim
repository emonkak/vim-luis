function! ku#source#tags#new(tag_files) abort
  let source = copy(s:Source)
  let source._tag_files = a:tag_files
  let source._cached_candidates = []
  return source
endfunction

function! s:action_open(kind, candidate) abort
  execute 'tag' a:candidate.word
  return 0
endfunction

function! s:action_open_x(kind, candidate) abort
  execute 'tag!' a:candidate.word
  return 0
endfunction

let s:Source = {
\   'name': 'tags',
\   'default_kind': {
\     'action_table': {
\       'open': function('s:action_open'),
\       'open_x': function('s:action_open_x'),
\     },
\     'key_table': {},
\     'prototype': g:ku#kind#common#export,
\   },
\   'matcher': g:ku#matcher#default,
\ }

function! s:Source.gather_candidates(pattern) abort dict
  return self._cached_candidates
endfunction

function! s:Source.on_source_enter() abort dict
  let candidates = []

  for tag_file in self._tag_files
    let lines = readfile(tag_file)
    for line in lines 
      let components = split(line, '\t')
      if len(components) < 2
        continue
      endif
      let [name, file; _rest] = components
      call add(candidates, {
      \   'word': name,
      \   'menu': file,
      \   'dup': 1,
      \ })
    endfor
  endfor

  let self._cached_candidates = candidates
endfunction
