let s:BORDER_ASCII = ['-', '|', '_', '|', '+', '+', '+', '+']

let s:BORDER_UNICODE = ['─', '│', '─', '│', '╭', '╮', '╯', '╰']

function! luis#previewer#popup#new(...) abort
  let options = get(a:000, 0, {})
  let previewer = copy(s:Previewer)
  let previewer._window = -1
  let previewer._popup_options = extend(
  \   {
  \     'border': [],
  \     'borderchars': &ambiwidth ==# 'double'
  \                    ? s:BORDER_ASCII
  \                    : s:BORDER_UNICODE,
  \     'borderhighlight': ['VertSplit'],
  \     'scrollbar': 0,
  \   },
  \   get(options, 'popup_options', {}),
  \   'force'
  \ )
  let previewer._window_options = extend(
  \   {
  \     'foldenable': 0,
  \     'scrolloff': 0,
  \     'signcolumn': 'no',
  \     'wincolor': 'Normal',
  \   },
  \   get(options, 'window_options', {}),
  \   'force'
  \ )
  return previewer
endfunction

let s:Previewer = {}

function! s:Previewer.bounds() abort dict
  if s:is_valid_window(self._window)
    let pos = popup_getpos(self._window)
    return {
    \   'row': pos.line,
    \   'col': pos.col,
    \   'width': pos.core_width,
    \   'height': pos.core_height,
    \ }
  else
    return { 'row': 0, 'col': 0, 'width': 0, 'height': 0 }
  endif
endfunction

function! s:Previewer.close() abort dict
  if s:is_valid_window(self._window)
    call popup_close(self._window)
    let self._window = -1
  endif
endfunction

function! s:Previewer.is_active() abort dict
  return s:is_valid_window(self._window)
endfunction

function! s:Previewer.open_buffer(bufnr, bounds, hints) abort dict
  if s:is_valid_window(self._window)
    call popup_close(self._window)
  endif

  let self._window = s:create_window(
  \   a:bufnr,
  \   a:bounds,
  \   a:hints,
  \   self._popup_options,
  \   self._window_options
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
  if s:is_valid_window(self._window)
    call popup_close(self._window)
  endif

  let self._window = s:create_window(
  \   a:lines,
  \   a:bounds,
  \   a:hints,
  \   self._popup_options,
  \   self._window_options
  \ )

  let bufnr = winbufnr(self._window)
  let filetype = has_key(a:hints, 'filetype')
  \            ? a:hints.filetype
  \            : has_key(a:hints, 'path')
  \            ? s:detect_filetype(self._window, bufnr, a:hints.path)
  \            : ''
  call setbufvar(bufnr, '&syntax', filetype)
endfunction

function! s:configure_popup(window, bounds, hints, popup_options) abort
  let popup_options = s:create_popup_options(a:hints, a:popup_options)

  call popup_setoptions(a:window, popup_options)

  call popup_move(a:window, {
  \   'line': a:bounds.row,
  \   'col': max([1, a:bounds.col]),
  \   'minwidth': a:bounds.width,
  \   'minheight': a:bounds.height,
  \   'maxwidth': a:bounds.width,
  \   'maxheight': a:bounds.height,
  \ })
endfunction

function! s:create_popup_options(hints, options) abort
  let options = copy(a:options)

  if get(a:hints, 'title', '') != ''
    " Add padding around title.
    let options.title = ' ' . a:hints.title . ' '
  endif

  return options
endfunction

function! s:create_window(content, bounds, hints, popup_options, window_options) abort
  let popup_options = s:create_popup_options(a:hints, a:popup_options)

  let popup_options.line = a:bounds.row
  let popup_options.col = a:bounds.col
  let popup_options.minwidth = a:bounds.width
  let popup_options.minheight = a:bounds.height
  let popup_options.maxwidth = a:bounds.width
  let popup_options.maxheight = a:bounds.height

  let original_eventignore = &eventignore
  set eventignore=BufEnter,BufLeave,BufWinEnter
  try
    let window = popup_create(a:content, popup_options)
  finally
    let &eventignore = original_eventignore
  endtry

  for [key, value] in items(a:window_options)
    call setwinvar(window, '&' . key, value)
  endfor

  return window
endfunction

function! s:detect_filetype(window, bufnr, path) abort
  " Ignore FileType event to prevent load filetype plugins.
  let original_eventignore = &eventignore
  set eventignore=FileType
  try
    let command = 'doautocmd <nomodeline> filetypedetect BufNewFile'
    \           . ' ' . fnameescape(a:path)
    call win_execute(a:window, command)
    return getbufvar(a:bufnr, '&filetype')
  finally
    let &eventignore = original_eventignore
  endtry
endfunction

function! s:is_valid_window(window) abort
  return a:window > 0 && win_gettype(a:window) ==# 'popup'
endfunction
