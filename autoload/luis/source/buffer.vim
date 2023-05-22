function! luis#source#buffer#new() abort
  let source = copy(s:Source)
  let source._cached_candidates = []
  return source
endfunction

let s:Source = {
\   'name': 'buffer',
\   'default_kind': luis#kind#buffer#import(),
\ }

function! s:Source.gather_candidates(context) abort dict
  return self._cached_candidates
endfunction

function! s:Source.on_source_enter(context) abort dict
  let candidates = []
  for bufinfo in getbufinfo({ 'buflisted': 1 })
    if bufinfo.name == ''
      let bufname = '[No Name]'
      let dup = 1
      let sort_priority = 3
    else
      let bufname = fnamemodify(bufinfo.name, ':~:.')
      let dup = 0
      let sort_priority = getbufvar(bufinfo.bufnr, '&buftype') != ''
      \                 ? 2
      \                 : bufname ==# bufinfo.name
      \                 ? 1
      \                 : 0
    endif
    call add(candidates, {
    \   'word': bufname,
    \   'menu': 'buffer ' . bufinfo.bufnr,
    \   'kind': s:buffer_indicator(bufinfo),
    \   'dup': dup,
    \   'user_data': {
    \     'buffer_nr': bufinfo.bufnr,
    \   },
    \   'luis_sort_priority': sort_priority,
    \ })
  endfor
  let self._cached_candidates = candidates
endfunction

function! s:Source.preview_candidate(candidate, context) abort
  if has_key(a:candidate.user_data, 'buffer_nr')
    return { 'type': 'buffer', 'bufnr': a:candidate.user_data.buffer_nr }
  else
    return { 'type': 'none' }
  endif
endfunction

function! s:buffer_indicator(bufinfo) abort
  let indicators = ''
  if !a:bufinfo.listed
    let indicators .= 'u'
  endif
  if a:bufinfo.bufnr == bufnr('%')
    let indicators .= '%'
  elseif a:bufinfo.bufnr == bufnr('#')
    let indicators .= '#'
  endif
  if a:bufinfo.loaded
    let indicators .= a:bufinfo.hidden ? 'h' : 'a'
  endif
  if !getbufvar(a:bufinfo.bufnr, '&modifiable')
    let indicators .= '-'
  endif
  if getbufvar(a:bufinfo.bufnr, '&readonly')
    let indicators .= '='
  endif
  if getbufvar(a:bufinfo.bufnr, '&modified')
    let indicators .= '+'
  endif
  return indicators
endfunction
