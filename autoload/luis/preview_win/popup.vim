let s:BORDER_ASCII = ['-', '|', '_', '|', '+', '+', '+', '+']

let s:BORDER_UNICODE = ['─', '│', '─', '│', '┌', '┐', '┘', '└']

if !exists('s:preview_bufnr')
  let s:preview_bufnr = -1
endif

function! luis#preview_win#popup#new(...) abort
  let preview_win = copy(s:PreviewWindow)
  let preview_win.popup_config = get(a:000, 0, {})
  let preview_win.window = -1
  return preview_win
endfunction

let s:PreviewWindow = {}

function! s:PreviewWindow.quit_preview() abort dict
  if s:is_valid_window(self.window)
    call popup_close(self.window)
    let self.window = -1
  endif
endfunction

function! s:PreviewWindow.is_active() abort dict
  return s:is_valid_window(self.window)
endfunction

function! s:PreviewWindow.preview_buffer(bufnr, dimensions, hints) abort dict
  if s:is_valid_window(self.window)
    call popup_close(self.window)
  endif

  let self.window = s:open_window(
  \   a:bufnr,
  \   a:dimensions,
  \   self.popup_config
  \ )

  if has_key(a:hints, 'pos')
    let command = printf(
    \   'call cursor(%d, %d) | normal! zt',
    \   a:hints.pos[0],
    \   a:hints.pos[1]
    \ )
    call win_execute(self.window, command)
  endif
endfunction

function! s:PreviewWindow.preview_text(lines, dimensions, hints) abort dict
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
      \   self.popup_config
      \ )
    endif
  else
    let self.window = s:open_window(
    \   s:preview_bufnr,
    \   a:dimensions,
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

function! s:open_window(bufnr, dimensions, override_config) abort
  let config = {
  \   'border': [],
  \   'borderchars': &ambiwidth ==# 'double'
  \                  ? s:BORDER_ASCII
  \                  : s:BORDER_UNICODE,
  \   'borderhighlight': ['VertSplit'],
  \   'scrollbar': 0,
  \ }

  call extend(config, a:override_config, 'force')

  let config.line = a:dimensions.row + 1  " 1 = {border_width}
  let config.col = max([1, a:dimensions.col])
  let config.minwidth = a:dimensions.width
  let config.minheight = a:dimensions.height
  let config.maxwidth = a:dimensions.width
  let config.maxheight = a:dimensions.height

  let preview_win = popup_create(a:bufnr, config)

  call setwinvar(preview_win, '&foldenable', 0)
  call setwinvar(preview_win, '&scrolloff', 0)
  call setwinvar(preview_win, '&signcolumn', 'no')
  call setwinvar(preview_win, '&wincolor', 'Normal')

  return preview_win
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
