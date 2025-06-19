function! luis#source#buffer#new(...) abort
  let options = get(a:000, 0, {})
  let source = copy(s:Source)
  let source._cached_candidates = []
  let source._sort_priority = get(options, 'sort_priority', function('s:default_sort_priority'))
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
  let SortPriority = self._sort_priority
  for bufinfo in getbufinfo({ 'buflisted': 1 })
    call add(candidates, {
    \   'word': bufinfo.name == '' ? '[No Name]' : bufname(bufinfo.bufnr),
    \   'menu': 'buffer ' . bufinfo.bufnr,
    \   'kind': s:buffer_indicator(bufinfo),
    \   'dup': bufinfo.name == '',
    \   'user_data': {
    \     'buffer_nr': bufinfo.bufnr,
    \     'preview_bufnr': bufinfo.bufnr,
    \   },
    \   'luis_sort_priority': SortPriority(bufinfo),
    \ })
  endfor
  let self._cached_candidates = candidates
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

function! s:default_sort_priority(bufinfo) abort
  let sort_priority = 0
  if a:bufinfo.name !=# ''
    let sort_priority -= 1
  endif
  if a:bufinfo.name !=# bufname(a:bufinfo.bufnr)
    let sort_priority -= 1
  endif
  if getbufvar(a:bufinfo.bufnr, '&buftype') == ''
    let sort_priority -= 1
  endif
  return sort_priority
endfunction
