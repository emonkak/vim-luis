function! luis#source#buffer#new() abort
  let source = copy(s:Source)
  let source.cached_candidates = []
  return source
endfunction

let s:Source = {
\   'name': 'buffer',
\   'default_kind': luis#kind#buffer#import(),
\ }

function! s:Source.gather_candidates(context) abort dict
  return self.cached_candidates
endfunction

function! s:Source.on_source_enter(context) abort dict
  let candidates = []
  for bufinfo in getbufinfo({ 'buflisted': 1 })
    let sort_priority = 0
    if bufinfo.name == ''
      let word = '[No Name]'
      let dup = 1
    else
      let word = fnamemodify(bufinfo.name, ':~:.')
      let dup = 0
      let sort_priority += 1
      if word ==# bufinfo.name
        let sort_priority += 1
      endif
      if getbufvar(bufinfo.bufnr, '&buftype') == ''
        let sort_priority += 1
      endif
    endif
    call add(candidates, {
    \   'word': word,
    \   'menu': 'buffer ' . bufinfo.bufnr,
    \   'kind': s:buffer_indicator(bufinfo),
    \   'dup': dup,
    \   'user_data': {
    \     'buffer_nr': bufinfo.bufnr,
    \     'preview_bufnr': bufinfo.bufnr,
    \   },
    \   'luis_sort_priority': sort_priority,
    \ })
  endfor
  let self.cached_candidates = candidates
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
