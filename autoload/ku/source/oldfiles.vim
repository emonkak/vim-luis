" ku source: oldfiles
" Module  "{{{1

let s:SOURCE_TEMPLATE = {
\   'name': 'oldfiles',
\   'default_kind': g:ku#kind#file#export,
\   'matcher': g:ku#matcher#default,
\   'gather_candidates': function('ku#source#oldfiles#gather_candidates'),
\   'on_source_enter': function('ku#source#oldfiles#on_source_enter'),
\ }

function! ku#source#oldfiles#new() abort
  return extend({'_cached_candidates': []}, s:SOURCE_TEMPLATE, 'keep')
endfunction








" Interface  "{{{1
function! ku#source#oldfiles#gather_candidates(pattern) abort dict  "{{{2
  return self._cached_candidates
endfunction




function! ku#source#oldfiles#on_source_enter() abort dict  "{{{2
  let candidates = []
  for i in range(len(v:oldfiles))
    let path = v:oldfiles[i]
    if !filereadable(path)
      continue
    endif
    call add(candidates, {
    \   'word': fnamemodify(path, ':~:.'),
    \   'user_data': {
    \     'ku_file_path': path,
    \   },
    \   'ku__sort_priority': i,
    \ })
  endfor
  let self._cached_candidates = candidates
endfunction








" __END__  "{{{1
" vim: foldmethod=marker
