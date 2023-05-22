let s:BORDER_ASCII = ['-', '|', '_', '|', '+', '+', '+', '+']

let s:BORDER_UNICODE = ['─', '│', '─', '│', '┌', '┐', '┘', '└']

if !exists('s:preview_bufnr')
  let s:preview_bufnr = -1
endif

function! luis#preview#popup#new(...) abort
  let preview = copy(s:Preview)
  let preview.popup_options = get(a:000, 0, {})
  let preview.preview_win = -1
  return preview
endfunction

let s:Preview = {}

function! s:Preview.close() abort dict
  if s:is_valid_window(self.preview_win)
    call popup_close(self.preview_win)
    let self.preview_win = -1
  endif
endfunction

function! s:Preview.is_active() abort dict
  return s:is_valid_window(self.preview_win)
endfunction

function! s:Preview.open_buffer(bufnr, lnum, dimensions) abort dict
  if s:is_valid_window(self.preview_win)
    call popup_close(self.preview_win)
  endif

  let self.preview_win = s:open_preview_win(
  \   a:bufnr,
  \   a:dimensions,
  \   self.popup_options
  \ )

  if a:lnum > 0
    let command = 'normal! ' . a:lnum . "ggz\<CR>"
    call win_execute(self.preview_win, command)
  endif
endfunction

function! s:Preview.open_text(lines, dimensions) abort dict
  if !bufexists(s:preview_bufnr)
    let s:preview_bufnr = bufadd('')
    call s:initialize_preview_buffer(s:preview_bufnr)
  elseif !bufloaded(s:preview_bufnr)
    call s:initialize_preview_buffer(s:preview_bufnr)
  endif

  if s:is_valid_window(self.preview_win)
    if winbufnr(self.preview_win) == s:preview_bufnr
      " Reuse window.
      call s:set_dimensions(self.preview_win, a:dimensions)
    else
      call popup_close(self.preview_win)
      let self.preview_win = s:open_preview_win(
      \   s:preview_bufnr,
      \   a:dimensions,
      \   self.popup_options
      \ )
    endif
  else
    let self.preview_win = s:open_preview_win(
    \   s:preview_bufnr,
    \   a:dimensions,
    \   self.popup_options
    \ )
  endif

  call deletebufline(s:preview_bufnr, 1, '$')
  call setbufline(s:preview_bufnr, 1, a:lines)
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

function! s:open_preview_win(bufnr, dimensions, override_options) abort
  let options = {
  \   'border': [],
  \   'borderchars': &ambiwidth ==# 'double'
  \                  ? s:BORDER_ASCII
  \                  : s:BORDER_UNICODE,
  \   'borderhighlight': ['NonText'],
  \   'scrollbar': 0,
  \ }

  call extend(options, a:override_options, 'force')

  let options.line = a:dimensions.row + 1  " 1 = {border_width}
  let options.col = max([1, a:dimensions.col])
  let options.minwidth = a:dimensions.width
  let options.minheight = a:dimensions.height
  let options.maxwidth = a:dimensions.width
  let options.maxheight = a:dimensions.height

  let preview_win = popup_create(a:bufnr, options)

  call setwinvar(preview_win, '&wincolor', 'Normal')
  call setwinvar(preview_win, '&scrolloff', 0)
  call setwinvar(preview_win, '&foldenable', 0)

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
