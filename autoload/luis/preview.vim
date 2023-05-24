if !exists('s:current_preview_win')
  let s:current_preview_win = 0
endif

function! luis#preview#attach_window(new_preview_win) abort
  if !luis#validations#validate_preview_window(a:new_preview_win)
    return 0
  endif
  let old_preview_win = s:current_preview_win
  let s:current_preview_win = a:new_preview_win
  if old_preview_win isnot 0
    call old_preview_win.quit_preview()
  endif
  return old_preview_win
endfunction

function! luis#preview#detach_window() abort
  let old_preview_win = s:current_preview_win
  let s:current_preview_win = 0
  if old_preview_win isnot 0
    call old_preview_win.quit_preview()
  endif
  return old_preview_win
endfunction

function! luis#preview#detect_filetype(path) abort
  if has('nvim')
    return luaeval(
    \   'vim.filetype.match({ filename = vim.api.nvim_eval("a:path") }) or ""'
    \ )
  else
    let temp_win = popup_create('', { 'hidden': 1 })
    let temp_bufnr = winbufnr(temp_win)
    try
      let command = 'doautocmd filetypedetect BufNewFile '
      \           . fnameescape(a:path)
      call win_execute(temp_win, command)
      return getbufvar(temp_bufnr, '&filetype')
    finally
      call popup_close(temp_win)
    endtry
  endif
endfunction

function! luis#preview#is_active() abort
  return s:current_preview_win isnot 0 && s:current_preview_win.is_active()
endfunction

function! luis#preview#is_enabled() abort
  return s:current_preview_win isnot 0
endfunction

function! luis#preview#quit() abort
  if s:current_preview_win isnot 0
    call s:current_preview_win.quit_preview()
  endif
endfunction

function! luis#preview#start(content, dimensions) abort
  if s:current_preview_win is 0
    return
  endif

  if a:content.type ==# 'text'
    let hints = {}
    if has_key(a:content, 'filetype')
      let hints.filetype = a:content.filetype
    endif
    call s:current_preview_win.preview_text(
    \   a:content.lines,
    \   a:dimensions,
    \   hints
    \ )
  elseif a:content.type ==# 'file'
    if filereadable(a:content.path)
      try
        let hints = {}
        let lines = readfile(a:content.path, '', a:dimensions.height)
        if has_key(a:content, 'filetype')
          let hints.filetype = a:content.filetype
        else
          let hints.filetype = luis#preview#detect_filetype(a:content.path)
        endif
        call s:current_preview_win.preview_text(
        \   lines,
        \   a:dimensions,
        \   hints
        \ )
      catch /\<E484:/
        call s:current_preview_win.quit_preview()
      endtry
    else
      call s:current_preview_win.quit_preview()
    endif
  elseif a:content.type ==# 'buffer'
    let hints = {}
    if has_key(a:content, 'pos')
      let hints.pos = a:content.pos
    endif
    call s:current_preview_win.preview_buffer(
    \   a:content.bufnr,
    \   a:dimensions,
    \   hints
    \ )
  else
    call s:current_preview_win.quit_preview()
  endif
endfunction
