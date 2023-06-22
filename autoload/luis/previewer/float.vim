function! luis#previewer#float#new(...) abort
  let previewer = copy(s:Previewer)
  let previewer.options = get(a:000, 0, {})
  let previewer.preview_bufnr = -1
  let previewer.window = -1
  return previewer
endfunction

let s:Previewer = {}

function! s:Previewer.close() abort dict
  call nvim_win_close(self.window, v:true)
  let self.window = -1
endfunction

function! s:Previewer.bounds() abort dict
  if s:is_valid_window(self.window)
    let [row, col] = nvim_win_get_position(self.window)
    let width = nvim_win_get_width(self.window)
    let height = nvim_win_get_height(self.window)
    return { 'row': row, 'col': col, 'width': width, 'height': height }
  else
    return { 'row': 0, 'col': 0, 'width': 0, 'height': 0 }
  endif
endfunction

function! s:Previewer.is_active() abort dict
  return s:is_valid_window(self.window)
endfunction

function! s:Previewer.open_buffer(bufnr, bounds, hints) abort dict
  if s:is_valid_window(self.window)
    call nvim_win_set_buf(self.window, a:bufnr)
    call s:set_bounds(self.window, a:bounds)
  else
    let self.window = s:open_window(
    \   a:bufnr,
    \   a:bounds,
    \   a:hints,
    \   self.options
    \ )
  endif

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
    let self.preview_bufnr = nvim_create_buf(v:false, v:true)
    call s:initialize_preview_buffer(self.preview_bufnr)
  elseif !bufloaded(self.preview_bufnr)
    call s:initialize_preview_buffer(self.preview_bufnr)
  endif

  if s:is_valid_window(self.window)
    call nvim_win_set_buf(self.window, self.preview_bufnr)
    call s:set_bounds(self.window, a:bounds)
  else
    let self.window = s:open_window(
    \   self.preview_bufnr,
    \   a:bounds,
    \   a:hints,
    \   self.options
    \ )
  endif

  let filetype = get(a:hints, 'filetype', '')
  call nvim_buf_set_lines(self.preview_bufnr, 0, -1, v:false, a:lines)
  call nvim_buf_set_option(self.preview_bufnr, 'filetype', filetype)
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

function! s:open_window(bufnr, bounds, hints, options) abort
  let config = {
  \    'border': 'single',
  \    'focusable': 0,
  \    'style': 'minimal',
  \ }

  if has_key(a:hints, 'title')
    let config.title = a:hints.title
    let config.title_pos = 'center'
  endif

  let config.relative = 'editor'
  let config.row = a:bounds.row
  let config.col = a:bounds.col
  let config.width = a:bounds.width
  let config.height = a:bounds.height

  if has_key(a:options, 'window_config')
    call extend(config, a:options.window_config, 'force')
  endif

  let window = nvim_open_win(a:bufnr, v:false, config)
  let options = { 'foldenable': v:false, 'scrolloff': 0, 'signcolumn': 'no' }

  if has_key(a:options, 'window_options')
    call extend(options, a:options.window_options, 'force')
  endif
  
  for [key, value] in items(options)
    call nvim_win_set_option(window, key, value)
  endfor

  return window
endfunction

function! s:set_bounds(win, bounds) abort
  call nvim_win_set_config(a:win, {
  \   'relative': 'editor',
  \   'row': a:bounds.row,
  \   'col': a:bounds.col,
  \   'width': a:bounds.width,
  \   'height': a:bounds.height,
  \ })
endfunction
