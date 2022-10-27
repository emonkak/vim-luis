" ku source: quickfix
" Module  "{{{1

let s:SOURCE_TEMPLATE = {
\   'gather_candidates': function('ku#source#quickfix#gather_candidates'),
\   'kind': {
\     'action_table': {
\       'open': function('ku#source#quickfix#action_open'),
\       'open!': function('ku#source#quickfix#action_open_x'),
\     },
\     'key_table': {},
\   },
\   'prototype': g:ku#kind#buffer#module,
\   'name': 'quickfix',
\   'on_action': function('ku#source#default#on_action'),
\   'on_source_enter': function('ku#source#quickfix#on_source_enter'),
\   'on_source_leave': function('ku#source#default#on_source_leave'),
\   'special_char_p': function('ku#source#default#special_char_p'),
\   'valid_for_acc_p': function('ku#source#default#valid_for_acc_p'),
\ }

function! ku#source#quickfix#new() abort
  return extend({'_cached_candidates': []}, s:SOURCE_TEMPLATE, 'keep')
endfunction








" Interface  "{{{1
function! ku#source#quickfix#gather_candidates(pattern) abort dict  "{{{2
  return self._cached_candidates
endfunction




function! ku#source#quickfix#on_source_enter() abort dict  "{{{2
  let qflist = getqflist()
  let first_errors_for_buffer = {}  " buffer number -> error number

  for i in range(len(qflist) - 1, 0, -1)
    let entry = qflist[i]
    if entry.valid
      let first_errors_for_buffer[entry.bufnr] = i + 1
    endif
  endfor

  let self._cached_candidates =
  \   map(items(first_errors_for_buffer), '{
  \     "word": bufname(v:val[0] + 0),
  \     "user_data": {
  \       "ku_buffer_nr": v:val[0] + 0,
  \       "ku_quickfix_nr": v:val[1],
  \     },
  \   }')
endfunction








" Actions  "{{{1
function! ku#source#quickfix#action_open(candidate) abort  "{{{2
  return s:open('', a:candidate)
endfunction




function! ku#source#quickfix#action_open_x(candidate) abort  "{{{2
  return s:open('!', a:candidate)
endfunction








" Misc.  {{{1
function! s:open(bang, candidate) abort  "{{{2
  let v:errmsg = ''

  let original_switchbuf = &switchbuf
  let &switchbuf = ''
  execute 'cc'.a:bang a:candidate.user_data.ku_quickfix_nr
  let &switchbuf = original_switchbuf

  return v:errmsg == '' ? 0 : v:errmsg
endfunction








" __END__  "{{{1
" vim: foldmethod=marker
