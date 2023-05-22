if !exists('s:preview_bufnr')
  let s:preview_bufnr = -1
endif

function! luis#preview#floats#new(...) abort
  let preview = copy(s:Preview)
  let preview.float_options = get(a:000, 0, {})
  let preview.preview_win = -1
  return preview
endfunction

let s:Preview = {}

function! s:Preview.close() abort dict
  if s:is_valid_window(self.preview_win)
    call nvim_win_close(self.preview_win, v:true)
    let self.preview_win = -1
  endif
endfunction

function! s:Preview.is_active() abort dict
  return s:is_valid_window(self.preview_win)
endfunction

function! s:Preview.open_buffer(bufnr, lnum, dimensions) abort dict
  if s:is_valid_window(self.preview_win)
    call nvim_win_set_buf(self.preview_win, a:bufnr)
    call s:set_dimensions(self.preview_win, a:dimensions)
  else
    let self.preview_win = s:open_preview_win(
    \   a:bufnr,
    \   a:dimensions,
    \   self.float_options
    \ )
  endif

  if a:lnum > 0
    let command = 'normal! ' . a:lnum . "ggz\<CR>"
    call win_execute(self.preview_win, command)
  endif
endfunction

function! s:Preview.open_text(lines, dimensions) abort dict
  if !bufexists(s:preview_bufnr)
    let s:preview_bufnr = nvim_create_buf(v:false, v:true)
    call s:initialize_preview_buffer(s:preview_bufnr)
  elseif !bufloaded(s:preview_bufnr)
    call s:initialize_preview_buffer(s:preview_bufnr)
  endif

  if s:is_valid_window(self.preview_win)
    call nvim_win_set_buf(self.preview_win, s:preview_bufnr)
    call s:set_dimensions(self.preview_win, a:dimensions)
  else
    let self.preview_win = s:open_preview_win(
    \   s:preview_bufnr,
    \   a:dimensions,
    \   self.float_options
    \ )
  endif

  call nvim_buf_set_lines(s:preview_bufnr, 0, -1, v:false, a:lines)
  call nvim_buf_set_lines(s:preview_bufnr, 0, -1, v:false, a:lines)
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

function! s:open_preview_win(bufnr, dimensions, override_options) abort
  let options = {
  \    'style': 'minimal',
  \    'border': 'single',
  \    'focusable': 0,
  \ }

  call extend(options, a:override_options, 'force')

  let options.relative = 'editor'
  let options.row = a:dimensions.row
  let options.col = a:dimensions.col
  let options.width = a:dimensions.width
  let options.height = a:dimensions.height
  let options.noautocmd = v:true

  let preview_win = nvim_open_win(a:bufnr, v:false, options)

  call nvim_win_set_option(preview_win, 'scrolloff', 0)
  call nvim_win_set_option(preview_win, 'foldenable', v:false)

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
