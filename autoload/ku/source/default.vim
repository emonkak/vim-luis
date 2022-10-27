" ku: source: default
" Interface  "{{{1
function! ku#source#default#gather_candidates(pattern) abort  "{{{2
  return []
endfunction




function! ku#source#default#on_action(candidate) abort  "{{{2
  return a:candidate
endfunction




function! ku#source#default#on_source_enter() abort  "{{{2
endfunction




function! ku#source#default#on_source_leave() abort  "{{{2
endfunction




function! ku#source#default#special_char_p(char) abort  "{{{2
  return 0
endfunction




function! ku#source#default#valid_for_acc_p(candidate, sep) abort  "{{{2
  return 1
endfunction








" __END__  "{{{1
" vim: foldmethod=marker

