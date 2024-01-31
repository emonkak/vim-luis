let s:BORDER_ASCII = ['-', '|', '_', '|', '+', '+', '+', '+']

let s:BORDER_UNICODE = ['─', '│', '─', '│', '╭', '╮', '╯', '╰']

function! luis#previewer#popup#new(...) abort
  let previewer = copy(s:Previewer)
  let previewer._bufnr = -1
  let previewer._options = get(a:000, 0, {})
  let previewer._window = -1
  return previewer
endfunction

let s:Previewer = {}

function! s:Previewer.bounds() abort dict
  if s:is_valid_window(self._window)
    let pos = popup_getpos(self._window)
    return {
    \   'row': pos.line - 1,
    \   'col': pos.col,
    \   'width': pos.core_width,
    \   'height': pos.core_height,
    \ }
  else
    return { 'row': 0, 'col': 0, 'width': 0, 'height': 0 }
  endif
endfunction

function! s:Previewer.close() abort dict
  call popup_close(self._window)
  let self._window = -1
endfunction

function! s:Previewer.is_active() abort dict
  return s:is_valid_window(self._window)
endfunction

function! s:Previewer.open_buffer(bufnr, bounds, hints) abort dict
  if s:is_valid_window(self._window)
    call popup_close(self._window)
  endif

  let self._window = s:open_window(
  \   a:bufnr,
  \   a:bounds,
  \   a:hints,
  \   self._options
  \ )

  if has_key(a:hints, 'cursor')
    let command = printf(
    \   'call cursor(%d, %d) | normal! zt',
    \   a:hints.cursor[0],
    \   a:hints.cursor[1]
    \ )
    call win_execute(self._window, command)
  endif
endfunction

function! s:Previewer.open_text(lines, bounds, hints) abort dict
  if !bufexists(self._bufnr)
    let self._bufnr = bufadd('')
    call s:initialize_preview_buffer(self._bufnr)
  elseif !bufloaded(self._bufnr)
    call s:initialize_preview_buffer(self._bufnr)
  endif

  if s:is_valid_window(self._window)
    if winbufnr(self._window) == self._bufnr
      " Reuse window.
      call s:set_bounds(self._window, a:bounds)
    else
      call popup_close(self._window)
      let self._window = s:open_window(
      \   self._bufnr,
      \   a:bounds,
      \   a:hints,
      \   self._options
      \ )
    endif
  else
    let self._window = s:open_window(
    \   self._bufnr,
    \   a:bounds,
    \   a:hints,
    \   self._options
    \ )
  endif

  call deletebufline(self._bufnr, 1, '$')
  call setbufline(self._bufnr, 1, a:lines)

  if has_key(a:hints, 'filetype')
    call setbufvar(self._bufnr, '&syntax', a:hints.filetype)
  elseif has_key(a:hints, 'path')
    let filetype = s:detect_filetype(self._window, self._bufnr, a:hints.path)
    call setbufvar(self._bufnr, '&syntax', filetype)
  else
    call setbufvar(self._bufnr, '&syntax', '')
  endif
endfunction

function! s:detect_filetype(window, bufnr, path) abort
  " Ignore FileType event to prevent load filetype plugins.
  let original_eventignore = &eventignore
  set eventignore=FileType
  try
    let command = 'doautocmd <nomodeline> filetypedetect BufNewFile'
    \           . ' ' . fnameescape(a:path)
    call win_execute(a:window, command)
    let filetype = getbufvar(a:bufnr, '&filetype')
    call setbufvar(a:bufnr, '&filetype', '')
    return filetype
  finally
    let &eventignore = original_eventignore
  endtry
endfunction

function! s:initialize_preview_buffer(bufnr) abort
  call setbufvar(a:bufnr, '&bufhidden', 'hide')
  call setbufvar(a:bufnr, '&buflisted', 0)
  call setbufvar(a:bufnr, '&buftype', 'nofile')
  call setbufvar(a:bufnr, '&foldenable', 0)
  call setbufvar(a:bufnr, '&swapfile', 0)
  call setbufvar(a:bufnr, '&undolevels', -1)
endfunction

function! s:is_valid_window(win) abort
  return a:win >= 0 && win_gettype(a:win) !=# 'unknown'
endfunction

function! s:open_window(bufnr, bounds, hints, options) abort
  let config = {
  \   'border': [],
  \   'borderchars': &ambiwidth ==# 'double'
  \                  ? s:BORDER_ASCII
  \                  : s:BORDER_UNICODE,
  \   'borderhighlight': ['VertSplit'],
  \   'scrollbar': 0,
  \ }

  if has_key(a:hints, 'title')
    let config.title = a:hints.title
  endif

  let config.line = a:bounds.row + 1  " 1 = {border_width}
  let config.col = max([1, a:bounds.col])
  let config.minwidth = a:bounds.width
  let config.minheight = a:bounds.height
  let config.maxwidth = a:bounds.width
  let config.maxheight = a:bounds.height

  if has_key(a:options, 'popup_config')
    call extend(config, a:options.popup_config, 'force')
  endif

  let original_eventignore = &eventignore
  set eventignore=BufEnter,BufLeave,BufWinEnter

  try
    let window = popup_create(a:bufnr, config)
  finally
    let &eventignore = original_eventignore
  endtry

  let options = {
  \   'foldenable': 0,
  \   'scrolloff': 0,
  \   'signcolumn': 'no',
  \   'wincolor': 'Normal',
  \ }

  if has_key(a:options, 'window_options')
    call extend(options, a:options.window_options, 'force')
  endif

  for [key, value] in items(options)
    call setwinvar(window, '&' . key, value)
  endfor

  return window
endfunction

function! s:set_bounds(win, bounds) abort
  " {line} = {row} + {border_width}
  call popup_move(a:win, {
  \   'line': a:bounds.row + 1,
  \   'col': max([1, a:bounds.col]),
  \   'minwidth': a:bounds.width,
  \   'minheight': a:bounds.height,
  \   'maxwidth': a:bounds.width,
  \   'maxheight': a:bounds.height,
  \ })
endfunction
