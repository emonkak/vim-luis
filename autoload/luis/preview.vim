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
    call old_preview_win.close()
  endif
  return old_preview_win
endfunction

function! luis#preview#detach_window() abort
  let old_preview_win = s:current_preview_win
  let s:current_preview_win = 0
  if old_preview_win isnot 0
    call old_preview_win.close()
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
  if s:current_preview_win is 0
    echoerr 'luis: Preview not available'
    return 0
  endif
  call s:current_preview_win.close()
  return 1
endfunction

function! luis#preview#start(session, dimensions) abort
  if s:current_preview_win is 0
    echoerr 'luis: Preview not available'
    return 0
  endif

  let candidate = a:session.guess_candidate()
  let context = {
  \   'preview_win': s:current_preview_win,
  \   'session': a:session,
  \ }

  if has_key(a:session.source, 'on_preview')
    call a:session.source.on_preview(candidate, context)
  endif

  if has_key(a:session.hook, 'on_preview')
    call a:session.hook.on_preview(candidate, context)
  endif

  if has_key(candidate.user_data, 'preview_lines')
    let hints = s:hints_from_candidate(candidate)
    call s:current_preview_win.open_text(
    \   candidate.user_data.preview_lines,
    \   a:dimensions,
    \   hints
    \ )
  elseif has_key(candidate.user_data, 'preview_path')
    let path = candidate.user_data.preview_path
    if filereadable(path)
      try
        let lines = readfile(path, '', a:dimensions.height)
        let hints = s:hints_from_candidate(candidate)
        call s:current_preview_win.open_text(
        \   lines,
        \   a:dimensions,
        \   hints
        \ )
      catch /\<E484:/
        call s:current_preview_win.close()
      endtry
    else
      call s:current_preview_win.close()
    endif
  elseif has_key(candidate.user_data, 'preview_bufnr')
    let bufnr = candidate.user_data.preview_bufnr
    if bufloaded(bufnr)
      let hints = s:hints_from_candidate(candidate)
      call s:current_preview_win.open_buffer(
      \   bufnr,
      \   a:dimensions,
      \   hints
      \ )
    else
      call s:current_preview_win.close()
    endif
  else
    call s:current_preview_win.close()
  endif
  
  return 1
endfunction

function! s:hints_from_candidate(candidate) abort
  let hints = {}

  if has_key(a:candidate.user_data, 'preview_title')
    let hints.title = a:candidate.user_data.preview_title
  endif

  if has_key(a:candidate.user_data, 'preview_cursor')
    let hints.cursor = a:candidate.user_data.preview_cursor
  endif

  if has_key(a:candidate.user_data, 'preview_filetype')
    let hints.filetype = a:candidate.user_data.preview_filetype
  else
    if has_key(a:candidate.user_data, 'preview_path')
      let path = a:candidate.user_data.preview_path
      let filetype = luis#preview#detect_filetype(path)
      if filetype != ''
        let hints.filetype = filetype
      endif
    endif
  endif

  return hints
endfunction
