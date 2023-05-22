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
        call add(errors_for_buffer[entry.bufnr], i + 1) 
      else
        let errors_for_buffer[entry.bufnr] = [i + 1 ]
      endif
    endif
  endfor

  let self._cached_candidates = map(items(errors_for_buffer), '{
  \   "word": bufname(v:val[0] + 0),
  \   "menu": len(v:val[1]) . " errors",
  \   "user_data": {
  \     "buffer_nr": v:val[0] + 0,
  \     "quickfix_nr": v:val[1][0],
  \   },
  \   "luis_sort_priority": v:val[1][0],
  \ }')
endfunction
