let s:BORDER_ASCII = ['-', '|', '_', '|', '+', '+', '+', '+']

let s:BORDER_UNICODE = ['─', '│', '─', '│', '╭', '╮', '╯', '╰']

function! luis#previewer#popup#new(...) abort
  let previewer = copy(s:Previewer)
  let previewer.options = get(a:000, 0, {})
  let previewer.preview_bufnr = -1
  let previewer.window = -1
  return previewer
endfunction

let s:Previewer = {}

function! s:Previewer.bounds() abort dict
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

function! s:Previewer.close() abort dict
  call popup_close(self.window)
  let self.window = -1
endfunction

function! s:Previewer.is_active() abort dict
  return s:is_valid_window(self.window)
endfunction

function! s:Previewer.open_buffer(bufnr, bounds, hints) abort dict
  if s:is_valid_window(self.window)
    call popup_close(self.window)
  endif

  let self.window = s:open_window(
  \   a:bufnr,
  \   a:bounds,
  \   a:hints,
  \   self.options
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

function! s:Previewer.open_text(lines, bounds, hints) abort dict
  if !bufexists(self.preview_bufnr)
    let self.preview_bufnr = bufadd('')
    call s:initialize_preview_buffer(self.preview_bufnr)
  elseif !bufloaded(self.preview_bufnr)
    call s:initialize_preview_buffer(self.preview_bufnr)
  endif

  if s:is_valid_window(self.window)
    if winbufnr(self.window) == self.preview_bufnr
      " Reuse window.
      call s:set_bounds(self.window, a:bounds)
    else
      call popup_close(self.window)
      let self.window = s:open_window(
      \   self.preview_bufnr,
      \   a:bounds,
      \   a:hints,
      \   self.options
      \ )
    endif
  else
    let self.window = s:open_window(
    \   self.preview_bufnr,
    \   a:bounds,
    \   a:hints,
    \   self.options
    \ )
  endif

  let filetype = get(a:hints, 'filetype', '')
  call deletebufline(self.preview_bufnr, 1, '$')
  call setbufline(self.preview_bufnr, 1, a:lines)
  call setbufvar(self.preview_bufnr, '&syntax', filetype)
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
  try
    let &eventignore = 'BufEnter,BufLeave,BufWinEnter'
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
