function! luis#source#quickfix#new() abort
  let source = copy(s:Source)
  let source.cached_candidates = []
  return source
endfunction

let s:Source = {
\   'name': 'quickfix',
\   'default_kind': luis#kind#quickfix#import(),
\ }

function! s:Source.gather_candidates(context) abort dict
  return self.cached_candidates
endfunction

function! s:Source.on_source_enter(context) abort dict
  let qflist = getqflist()
  let error_count_for_buffer = {}  " buffer number -> erorr count
  let first_errors = []

  for i in range(len(qflist))
    let entry = qflist[i]
    if entry.valid
      if has_key(error_count_for_buffer, entry.bufnr)
        let error_count_for_buffer[entry.bufnr] += 1
      else
        let error_count_for_buffer[entry.bufnr] = 1
        call add(first_errors, i)
      endif
    endif
  endfor

  let candidates = []

  for i in first_errors
    let entry = qflist[i]
    let error_count = error_count_for_buffer[entry.bufnr]
    call add(candidates, {
    \   'word': bufname(entry.bufnr),
    \   'menu': error_count . ' errors',
    \   'user_data': {
    \     'buffer_nr': entry.bufnr,
    \     'buffer_cursor': [entry.lnum, entry.col],
    \     'preview_bufnr': entry.bufnr,
    \     'preview_cursor': [entry.lnum, entry.col],
    \     'quickfix_nr': i + 1,
    \   },
    \   'luis_sort_priority': -i,
    \ })
  endfor

  let self.cached_candidates = candidates
endfunction
