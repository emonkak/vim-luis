if !exists('s:preview_bufnr')
  let s:preview_bufnr = -1
endif

function! luis#preview_win#floats#new(...) abort
  let preview_win = copy(s:PreviewWindow)
  let preview_win.float_config = get(a:000, 0, {})
  let preview_win.window = -1
  return preview_win
endfunction

let s:PreviewWindow = {}

function! s:PreviewWindow.is_active() abort dict
  return s:is_valid_window(self.window)
endfunction

function! s:PreviewWindow.preview_buffer(bufnr, dimensions, hints) abort dict
  if s:is_valid_window(self.window)
    call nvim_win_set_buf(self.window, a:bufnr)
    call s:set_dimensions(self.window, a:dimensions)
  else
    let self.window = s:open_window(
    \   a:bufnr,
    \   a:dimensions,
    \   self.float_config
    \ )
  endif

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
    let s:preview_bufnr = nvim_create_buf(v:false, v:true)
    call s:initialize_preview_buffer(s:preview_bufnr)
  elseif !bufloaded(s:preview_bufnr)
    call s:initialize_preview_buffer(s:preview_bufnr)
  endif

  if s:is_valid_window(self.window)
    call nvim_win_set_buf(self.window, s:preview_bufnr)
    call s:set_dimensions(self.window, a:dimensions)
  else
    let self.window = s:open_window(
    \   s:preview_bufnr,
    \   a:dimensions,
    \   self.float_config
    \ )
  endif

  call nvim_buf_set_lines(s:preview_bufnr, 0, -1, v:false, a:lines)

  let filetype = get(a:hints, 'filetype', '')
  call nvim_buf_set_option(s:preview_bufnr, 'filetype', filetype)
endfunction

function! s:PreviewWindow.quit_preview() abort dict
  if s:is_valid_window(self.window)
    call nvim_win_close(self.window, v:true)
    let self.window = -1
  endif
endfunction

function! s:initialize_preview_buffer(bufnr) abort
  call nvim_buf_set_option(a:bufnr, 'bufhidden', 'hide')
  call nvim_buf_set_option(a:bufnr, 'buflisted', v:false)
  call nvim_buf_set_option(a:bufnr, 'buftype', 'nofile')
  call nvim_buf_set_option(a:bufnr, 'swapfile', v:false)
  call nvim_buf_set_option(a:bufnr, 'undolevels', -1)
endfunction

function! s:is_valid_window(win) abort
  return a:win >= 0 && nvim_win_is_valid(a:win)
endfunction

function! s:open_window(bufnr, dimensions, override_config) abort
  let config = {
  \    'style': 'minimal',
  \    'border': 'single',
  \    'focusable': 0,
  \ }

  call extend(config, a:override_config, 'force')

  let config.relative = 'editor'
  let config.row = a:dimensions.row
  let config.col = a:dimensions.col
  let config.width = a:dimensions.width
  let config.height = a:dimensions.height
  let config.noautocmd = v:true

  let preview_win = nvim_open_win(a:bufnr, v:false, config)

  call nvim_win_set_option(preview_win, 'foldenable', v:false)
  call nvim_win_set_option(preview_win, 'scrolloff', 0)
  call nvim_win_set_option(preview_win, 'signcolumn', 'no')

  return preview_win
endfunction

function! s:set_dimensions(win, dimensions) abort
  call nvim_win_set_config(a:win, {
  \   'relative': 'editor',
  \   'row': a:dimensions.row,
  \   'col': a:dimensions.col,
  \   'width': a:dimensions.width,
  \   'height': a:dimensions.height,
  \ })
endfunction
