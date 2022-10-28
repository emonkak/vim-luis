" ku source: oldfiles
" Module  "{{{1

let s:SOURCE_TEMPLATE = {
\   'name': 'oldfiles',
\   'kind': g:ku#kind#file#module,
\   'matcher': g:ku#matcher#default,
\   'gather_candidates': function('ku#source#oldfiles#gather_candidates'),
\   'on_action': function('ku#source#default#on_action'),
\   'on_source_enter': function('ku#source#oldfiles#on_source_enter'),
\   'on_source_leave': function('ku#source#default#on_source_leave'),
\   'special_char_p': function('ku#source#default#special_char_p'),
\   'valid_for_acc_p': function('ku#source#default#valid_for_acc_p'),
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
