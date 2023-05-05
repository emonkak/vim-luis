function! luis#source#quickfix#new() abort
  let source = copy(s:Source)
  let source._cached_candidates = []
  return source
endfunction

let s:Source = {
\   'name': 'quickfix',
\   'default_kind': g:luis#kind#quickfix#export,
\   'matcher': g:luis#matcher#default,
\ }

function! s:Source.gather_candidates(context) abort dict
  return self._cached_candidates
endfunction

function! s:Source.on_source_enter() abort dict
  let qflist = getqflist()
  let first_errors_for_buffer = {}  " buffer number -> error number

  for i in range(len(qflist) - 1, 0, -1)
    let entry = qflist[i]
    if entry.valid
      let first_errors_for_buffer[entry.bufnr] = i + 1
    endif
  endfor

  let self._cached_candidates = map(items(first_errors_for_buffer), '{
  \   "word": bufname(v:val[0] + 0),
  \   "user_data": {
  \     "buffer_nr": v:val[0] + 0,
  \     "quickfix_nr": v:val[1],
  \   },
  \   "luis_sort_priority": v:val[1],
  \ }')
endfunction
