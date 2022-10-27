" ku source: colorscheme
" Module  "{{{1

let s:SOURCE_TEMPLATE = {
\   'gather_candidates': function('ku#source#colorscheme#gather_candidates'),
\   'kind': {
\     'action_table': {
\       'open': function('ku#source#colorscheme#action_open'),
\     },
\     'key_table': {},
\     'prototype': ku#kind#common#module,
\   },
\   'name': 'colorscheme',
\   'on_action': function('ku#source#default#on_action'),
\   'on_source_enter': function('ku#source#colorscheme#on_source_enter'),
\   'on_source_leave': function('ku#source#default#on_source_leave'),
\   'special_char_p': function('ku#source#default#special_char_p'),
\   'valid_for_acc_p': function('ku#source#default#valid_for_acc_p'),
\ }

function! ku#source#colorscheme#new() abort
  return extend({'_cached_candidates': []}, s:SOURCE_TEMPLATE, 'keep')
endfunction








" Interface  "{{{1
function! ku#source#colorscheme#gather_candidates(pattern) abort dict  "{{{2
  return self._cached_candidates
endfunction




function! ku#source#colorscheme#on_source_enter() abort dict  "{{{2
  let candidates = globpath(&runtimepath, 'colors/*.vim', 0, 1)
  call map(candidates, '{
  \   "word": fnamemodify(v:val, ":t:r"),
  \   "menu": fnamemodify(v:val, ":p:h:h:~"),
  \ }')
  let self._cached_candidates = candidates
endfunction








" Actions  "{{{1
function! ku#source#colorscheme#action_open(candidate)  "{{{2
  let v:errmsg = ''
  execute 'colorscheme' a:candidate.word
  return v:errmsg == '' ? 0 : v:errmsg
endfunction








" __END__  "{{{1
" vim: foldmethod=marker
