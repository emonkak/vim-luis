let s:BORDER_ASCII = ['-', '|', '_', '|', '+', '+', '+', '+']

let s:BORDER_UNICODE = ['─', '│', '─', '│', '┌', '┐', '┘', '└']

if !exists('s:preview_bufnr')
  let s:preview_bufnr = -1
endif

function! luis#preview#popup#new(...) abort
  let preview = copy(s:PreviewWindow)
  let preview.popup_config = get(a:000, 0, {})
  let preview.window = -1
  return preview
endfunction

let s:PreviewWindow = {}

function! s:PreviewWindow.close() abort dict
  if s:is_valid_window(self.window)
    call popup_close(self.window)
    let self.window = -1
  endif
endfunction

function! s:PreviewWindow.dimensions() abort dict
  if s:is_valid_window(self.window)
    let pos = popup_getpos(self.window)
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

function! s:PreviewWindow.is_active() abort dict
  return s:is_valid_window(self.window)
endfunction

function! s:PreviewWindow.open_buffer(bufnr, dimensions, hints) abort dict
  if s:is_valid_window(self.window)
    call popup_close(self.window)
  endif

  let self.window = s:open_window(
  \   a:bufnr,
  \   a:dimensions,
  \   a:hints,
  \   self.popup_config
  \ )

  if has_key(a:hints, 'cursor')
    let command = printf(
    \   'call cursor(%d, %d) | normal! zt',
    \   a:hints.cursor[0],
    \   a:hints.cursor[1]
    \ )
    call win_execute(self.window, command)
  endif
endfunction

function! s:PreviewWindow.open_text(lines, dimensions, hints) abort dict
  if !bufexists(s:preview_bufnr)
    let s:preview_bufnr = bufadd('')
    call s:initialize_preview_buffer(s:preview_bufnr)
  elseif !bufloaded(s:preview_bufnr)
    call s:initialize_preview_buffer(s:preview_bufnr)
  endif

  if s:is_valid_window(self.window)
    if winbufnr(self.window) == s:preview_bufnr
      " Reuse window.
      call s:set_dimensions(self.window, a:dimensions)
    else
      call popup_close(self.window)
      let self.window = s:open_window(
      \   s:preview_bufnr,
      \   a:dimensions,
      \   a:hints,
      \   self.popup_config
      \ )
    endif
  else
    let self.window = s:open_window(
    \   s:preview_bufnr,
    \   a:dimensions,
    \   a:hints,
    \   self.popup_config
    \ )
  endif

  call deletebufline(s:preview_bufnr, 1, '$')
  call setbufline(s:preview_bufnr, 1, a:lines)

  let filetype = get(a:hints, 'filetype', '')
  call setbufvar(s:preview_bufnr, '&filetype', filetype)
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

function! s:open_window(bufnr, dimensions, hints, override_config) abort
  let config = {
  \   'border': [],
  \   'borderchars': &ambiwidth ==# 'double'
  \                  ? s:BORDER_ASCII
  \                  : s:BORDER_UNICODE,
  \   'borderhighlight': ['VertSplit'],
  \   'scrollbar': 0,
  \ }

  call extend(config, a:override_config, 'force')

  if has_key(a:hints, 'title')
    let config.title = a:hints.title
  endif

  let config.line = a:dimensions.row + 1  " 1 = {border_width}
  let config.col = max([1, a:dimensions.col])
  let config.minwidth = a:dimensions.width
  let config.minheight = a:dimensions.height
  let config.maxwidth = a:dimensions.width
  let config.maxheight = a:dimensions.height

  let preview = popup_create(a:bufnr, config)

  call setwinvar(preview, '&foldenable', 0)
  call setwinvar(preview, '&scrolloff', 0)
  call setwinvar(preview, '&signcolumn', 'no')
  call setwinvar(preview, '&wincolor', 'Normal')

  return preview
endfunction

function! s:set_dimensions(win, dimensions) abort
  " {line} = {row} + {border_width}
  call popup_move(a:win, {
  \   'line': a:dimensions.row + 1,
  \   'col': max([1, a:dimensions.col]),
  \   'minwidth': a:dimensions.width,
  \   'minheight': a:dimensions.height,
  \   'maxwidth': a:dimensions.width,
  \   'maxheight': a:dimensions.height,
  \ })
endfunction
