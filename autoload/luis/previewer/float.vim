function! luis#previewer#float#new(...) abort
  let options = get(a:000, 0, {})
  let previewer = copy(s:Previewer)
  let previewer._bufnr = -1
  let previewer._window = -1
  let previewer._window_config = extend(
  \   {
  \     'border': 'rounded',
  \     'focusable': 0,
  \     'style': 'minimal',
  \   },
  \   get(options, 'window_config', {}),
  \   'force'
  \ )
  let previewer._window_options = extend(
  \   {
  \     'foldenable': v:false,
  \     'scrolloff': 0,
  \     'signcolumn': 'no',
  \   },
  \   get(options, 'window_options', {}),
  \   'force'
  \ )
  return previewer
endfunction

let s:Previewer = {}

function! s:Previewer.close() abort dict
  if s:is_valid_window(self._window)
    call nvim_win_close(self._window, v:true)
    let self._window = -1
  endif
endfunction

function! s:Previewer.bounds() abort dict
  if s:is_valid_window(self._window)
    let [row, col] = nvim_win_get_position(self._window)
    let width = nvim_win_get_width(self._window)
    let height = nvim_win_get_height(self._window)
    return { 'row': row + 1, 'col': col + 1, 'width': width, 'height': height }
  else
    return { 'row': 0, 'col': 0, 'width': 0, 'height': 0 }
  endif
endfunction

function! s:Previewer.is_active() abort dict
  return s:is_valid_window(self._window)
endfunction

function! s:Previewer.open_buffer(bufnr, bounds, hints) abort dict
  if s:is_valid_window(self._window)
    call s:switch_buffer_without_events(self._window, a:bufnr)
    call s:configure_window(
    \   self._window,
    \   a:bounds,
    \   a:hints,
    \   self._window_config
    \ )
  else
    let self._window = s:open_window(
    \   a:bufnr,
    \   a:bounds,
    \   a:hints,
    \   self._window_config,
    \   self._window_options
    \ )
  endif

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
    let self._bufnr = nvim_create_buf(v:false, v:true)
    call s:initialize_preview_buffer(self._bufnr)
  elseif !bufloaded(self._bufnr)
    call s:initialize_preview_buffer(self._bufnr)
  endif

  if s:is_valid_window(self._window)
    call s:switch_buffer_without_events(self._window, self._bufnr)
    call s:configure_window(
    \   self._window,
    \   a:bounds,
    \   a:hints,
    \   self._window_config
    \ )
  else
    let self._window = s:open_window(
    \   self._bufnr,
    \   a:bounds,
    \   a:hints,
    \   self._window_config,
    \   self._window_options
    \ )
  endif

  call nvim_buf_set_lines(self._bufnr, 0, -1, v:false, a:lines)

  let filetype = has_key(a:hints, 'filetype')
  \            ? a:hints.filetype
  \            : has_key(a:hints, 'path')
  \            ? s:detect_filetype(self._bufnr, a:hints.path)
  \            : ''
  call nvim_buf_set_option(self._bufnr, 'syntax', filetype)
endfunction

function! s:configure_window(window, bounds, hints, config) abort
  let config = s:create_window_config(a:bounds, a:hints, a:config)
  call nvim_win_set_config(a:window, config)
endfunction

function! s:create_window_config(bounds, hints, default_config) abort
  let config = copy(a:default_config)
  let config.relative = 'editor'
  " "row" and "col" are relative positions from (1, 1). So we subtract 1 to
  " convert to absolute positions.
  let config.row = a:bounds.row - 1
  let config.col = a:bounds.col - 1
  let config.width = a:bounds.width
  let config.height = a:bounds.height

  if get(a:hints, 'title', '') != ''
    " Add padding around title.
    let config.title = ' ' . a:hints.title . ' '
  endif

  return config
endfunction

function! s:detect_filetype(bufnr, path) abort
  let SCRIPT =<< trim END
  vim.filetype.match({
    buf = vim.api.nvim_eval('a:bufnr'),
    filename = vim.api.nvim_eval('a:path'),
  }) or ''
END
  return luaeval(join(SCRIPT, ''))
endfunction

function! s:initialize_preview_buffer(bufnr) abort
  call nvim_buf_set_option(a:bufnr, 'bufhidden', 'hide')
  call nvim_buf_set_option(a:bufnr, 'buflisted', v:false)
  call nvim_buf_set_option(a:bufnr, 'buftype', 'nofile')
  call nvim_buf_set_option(a:bufnr, 'swapfile', v:false)
  call nvim_buf_set_option(a:bufnr, 'undolevels', -1)
endfunction

function! s:is_valid_window(window) abort
  return a:window > 0 && nvim_win_is_valid(a:window)
endfunction

function! s:open_window(bufnr, bounds, hints, config, options) abort
  let config = s:create_window_config(a:bounds, a:hints, a:config)
  let config.noautocmd = v:true

  let window = nvim_open_win(a:bufnr, v:false, config)

  for [key, value] in items(a:options)
    call nvim_win_set_option(window, key, value)
  endfor

  return window
endfunction

function! s:switch_buffer_without_events(window, bufnr) abort
  let original_eventignore = &eventignore
  set eventignore=BufEnter,BufLeave,BufWinEnter
  try
    call nvim_win_set_buf(a:window, a:bufnr)
  finally
    let &eventignore = original_eventignore
  endtry
endfunction
