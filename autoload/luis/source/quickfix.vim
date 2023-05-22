function! luis#source#quickfix#new() abort
  let source = copy(s:Source)
  let source._cached_candidates = []
  return source
endfunction

let s:Source = {
\   'name': 'quickfix',
\   'default_kind': luis#kind#quickfix#import(),
\ }

function! s:Source.gather_candidates(context) abort dict
  return self._cached_candidates
endfunction

function! s:Source.on_source_enter(context) abort dict
  let qflist = getqflist()
  let errors_for_buffer = {}  " buffer number -> [error number]

  for i in range(len(qflist))
    let entry = qflist[i]
    if entry.valid
      if has_key(errors_for_buffer, entry.bufnr)
        call add(errors_for_buffer[entry.bufnr], i)
      else
        let errors_for_buffer[entry.bufnr] = [i]
      endif
    endif
  endfor

  let candidates = []

  for [key, errors] in items(errors_for_buffer)
    let first_error = errors[0]
    let entry = qflist[first_error]
    call add(candidates, {
    \   'word': bufname(entry.bufnr),
    \   'menu': len(errors) . ' errors',
    \   'user_data': {
    \     'buffer_nr': entry.bufnr,
    \     'buffer_pos': [entry.lnum, entry.col],
    \     'quickfix_nr': first_error + 1,
    \   },
    \   'luis_sort_priority': first_error,
    \ })
  endfor

  let self._cached_candidates = candidates
endfunction

function! s:Source.preview_candidate(candidate, context) abort
  if has_key(a:candidate.user_data, 'buffer_nr')
  \  && has_key(a:candidate.user_data, 'buffer_pos')
    return {
    \   'type': 'buffer',
    \   'bufnr': a:candidate.user_data.buffer_nr,
    \   'lnum': a:candidate.user_data.buffer_pos[0],
    \ }
  else
    return { 'type': 'none' }
  endif
endfunction
