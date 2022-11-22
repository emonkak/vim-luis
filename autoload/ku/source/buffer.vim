" ku source: buffer
" Module  "{{{1

let s:SOURCE_TEMPLATE = {
\   'name': 'buffer',
\   'default_kind': g:ku#kind#buffer#module,
\   'matcher': g:ku#matcher#default,
\   'gather_candidates': function('ku#source#buffer#gather_candidates'),
\   'on_action': function('ku#source#default#on_action'),
\   'on_source_enter': function('ku#source#buffer#on_source_enter'),
\   'on_source_leave': function('ku#source#default#on_source_leave'),
\   'special_char_p': function('ku#source#default#special_char_p'),
\   'valid_for_acc_p': function('ku#source#default#valid_for_acc_p'),
\ }

function! ku#source#buffer#new() abort
  return extend({'_cached_candidates': []}, s:SOURCE_TEMPLATE, 'keep')
endfunction








" Interface  "{{{1
function! ku#source#buffer#gather_candidates(pattern) abort dict  "{{{2
  return self._cached_candidates
endfunction




function! ku#source#buffer#on_source_enter() abort dict  "{{{2
  let candidates = []
  for i in range(1, bufnr('$'))
    if !bufexists(i) || !buflisted(i)
      continue
    endif
    let bufname = bufname(i)
    if empty(bufname)
      let bufname = '[No Name]'
      let dup = 1
      let sort_priority = 3
    else
      let dup = 0
      if getbufvar(i, '&buftype') != ''
        let sort_priority = 2
      elseif bufname ==# fnamemodify(bufname, ':p')
        let sort_priority = 1
      else
        let sort_priority = 0
      endif
    endif
    call add(candidates, {
    \   'word': bufname,
    \   'menu': printf('buffer %*d', len(bufnr('$')), i),
    \   'dup': dup,
    \   'user_data': {
    \     'ku_buffer_nr': i,
    \   },
    \   'ku__sort_priority': sort_priority,
    \ })
  endfor
  let self._cached_candidates = candidates
endfunction








" __END__  "{{{1
" vim: foldmethod=marker
