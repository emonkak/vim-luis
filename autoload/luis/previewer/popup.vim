let s:BORDER_ASCII = ['-', '|', '_', '|', '+', '+', '+', '+']

let s:BORDER_UNICODE = ['─', '│', '─', '│', '╭', '╮', '╯', '╰']

function! luis#previewer#popup#new(...) abort
  let options = get(a:000, 0, {})
  let previewer = copy(s:Previewer)
  let previewer._bufnr = -1
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

  let self._window = s:open_window(
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
  if !bufexists(self._bufnr)
    let self._bufnr = bufadd('')
    call s:initialize_preview_buffer(self._bufnr)
  elseif !bufloaded(self._bufnr)
    call s:initialize_preview_buffer(self._bufnr)
  endif

  if s:is_valid_window(self._window)
    if winbufnr(self._window) == self._bufnr
      " Reuse window.
      call s:configure_popup(
      \   self._window,
      \   a:bounds,
      \   a:hints,
      \   self._popup_options
      \ )
    else
      call popup_close(self._window)
      let self._window = s:open_window(
      \   self._bufnr,
      \   a:bounds,
      \   a:hints,
      \   self._popup_options,
      \   self._window_options
      \ )
    endif
  else
    let self._window = s:open_window(
    \   self._bufnr,
    \   a:bounds,
    \   a:hints,
    \   self._popup_options,
    \   self._window_options
    \ )
  endif

  call deletebufline(self._bufnr, 1, '$')
  call setbufline(self._bufnr, 1, a:lines)

  let filetype = has_key(a:hints, 'filetype')
  \            ? a:hints.filetype
  \            : has_key(a:hints, 'path')
  \            ? s:detect_filetype(self._window, self._bufnr, a:hints.path)
  \            : ''
  call setbufvar(self._bufnr, '&syntax', filetype)
endfunction

function! s:configure_popup(window, bounds, hints, popup_options) abort
  let popup_options = s:create_popup_options(a:hints, a:popup_options)

  call popup_setoptions(a:window, popup_options)

  " line = row + border_width
  call popup_move(a:window, {
  \   'line': a:bounds.row + 1,
  \   'col': max([1, a:bounds.col]),
  \   'minwidth': a:bounds.width,
  \   'minheight': a:bounds.height,
  \   'maxwidth': a:bounds.width,
  \   'maxheight': a:bounds.height,
  \ })
endfunction

function! s:create_popup_options(hints, default_options) abort
  let options = copy(a:default_options)
  let title = ''

  if has_key(a:hints, 'title')
    let title = a:hints.title
  elseif has_key(a:hints, 'bufnr')
    let title = bufname(a:hints.bufnr)
    let title = title != '' ? fnamemodify(title, ':t') : '[No Name]'
  elseif has_key(a:hints, 'path')
    let title = fnamemodify(a:hints.path, ':t')
  endif

  if title != ''
    " Add padding around title.
    let options.title = ' ' . title . ' '
  endif

  return options
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

function! s:is_valid_window(window) abort
  return a:window > 0 && win_gettype(a:window) ==# 'popup'
endfunction

function! s:open_window(bufnr, bounds, hints, popup_options, window_options) abort
  let popup_options = s:create_popup_options(a:hints, a:popup_options)

  " line = row + border_width
  let popup_options.line = a:bounds.row + 1
  let popup_options.col = max([1, a:bounds.col])
  let popup_options.minwidth = a:bounds.width
  let popup_options.minheight = a:bounds.height
  let popup_options.maxwidth = a:bounds.width
  let popup_options.maxheight = a:bounds.height

  let original_eventignore = &eventignore
  set eventignore=BufEnter,BufLeave,BufWinEnter

  try
    let window = popup_create(a:bufnr, popup_options)
  finally
    let &eventignore = original_eventignore
  endtry

  for [key, value] in items(a:window_options)
    call setwinvar(window, '&' . key, value)
  endfor

  return window
endfunction
