function! luis#source#buffer#new() abort
  let source = copy(s:Source)
  let source._cached_candidates = []
  return source
endfunction

let s:Source = {
\   'name': 'buffer',
\   'default_kind': g:luis#kind#buffer#export,
\   'matcher': g:luis#matcher#default,
\ }

function! s:Source.gather_candidates(args) abort dict
  return self._cached_candidates
endfunction

function! s:Source.on_preview(candidate) abort dict
  let bufnr = has_key(a:candidate.user_data, 'buffer_nr')
  \         ? a:candidate.user_data.buffer_nr
  \         : self._alternate_bufnr
  call s:switch_last_window(bufnr)
endfunction

function! s:Source.on_source_enter() abort dict
  let candidates = []
  let max_bufnr = bufnr('$')
  for buf in getbufinfo({ 'buflisted': 1 })
    if empty(buf.name)
      let bufname = '[No Name]'
      let dup = 1
      let sort_priority = 3
    else
      let bufname = fnamemodify(buf.name, ':~:.')
      let dup = 0
      let sort_priority = getbufvar(buf.bufnr, '&buftype') != ''
      \                 ? 2
      \                 : bufname ==# buf.name
      \                 ? 1
      \                 : 0
    endif
    call add(candidates, {
    \   'word': bufname,
    \   'menu': printf('buffer %*d', len(max_bufnr), buf.bufnr),
    \   'kind': s:buffer_indicator(buf),
    \   'dup': dup,
    \   'user_data': {
    \     'buffer_nr': buf.bufnr,
    \   },
    \   'luis_sort_priority': sort_priority,
    \ })
  endfor
  let self._cached_candidates = candidates
  let self._alternate_bufnr = bufnr('#')
endfunction

function! s:Source.on_source_leave() abort dict
  let bufnr = self._alternate_bufnr
  call s:switch_last_window(bufnr)
endfunction

function! s:buffer_indicator(buf) abort
  let indicators = ''
  if !a:buf.listed
    let indicators .= 'u'
  endif
  if a:buf.bufnr == bufnr('%')
    let indicators .= '%'
  elseif a:buf.bufnr == bufnr('#')
    let indicators .= '#'
  endif
  if a:buf.loaded
    let indicators .= a:buf.hidden ? 'h' : 'a'
  endif
  if !getbufvar(a:buf.bufnr, '&modifiable')
    let indicators .= '-'
  endif
  if getbufvar(a:buf.bufnr, '&readonly')
    let indicators .= '='
  endif
  if getbufvar(a:buf.bufnr, '&modified')
    let indicators .= '+'
  endif
  return indicators
endfunction

function! s:switch_last_window(bufnr) abort
  let original_winnr = winnr()
  noautocmd wincmd p  " Prevent close luis window
  noautocmd execute 'buffer' a:bufnr
  noautocmd execute original_winnr 'wincmd w'
endfunction
