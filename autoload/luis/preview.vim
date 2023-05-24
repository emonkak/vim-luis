if !exists('s:current_preview')
  let s:current_preview = 0
endif

function! luis#preview#close() abort
  if s:current_preview isnot 0
    call s:current_preview.close()
  endif
endfunction

function! luis#preview#disable() abort
  let old_preview = s:current_preview
  let s:current_preview = 0
  return old_preview
endfunction

function! luis#preview#enable(new_preview) abort
  if !luis#validations#validate_preview(a:new_preview)
    return 0
  endif
  let old_preview = s:current_preview
  let s:current_preview = a:new_preview
  return old_preview
endfunction

function! luis#preview#is_active() abort
  return s:current_preview isnot 0 && s:current_preview.is_active()
endfunction

function! luis#preview#is_enabled() abort
  return s:current_preview isnot 0
endfunction

function! luis#preview#open(content, dimensions) abort
  if s:current_preview isnot 0
    if a:content.type ==# 'text'
      call s:current_preview.open_text(a:content.lines, a:dimensions)
    elseif a:content.type ==# 'buffer'
      let lnum = get(a:content, 'lnum', 0)
      call s:current_preview.open_buffer(a:content.bufnr, lnum, a:dimensions)
    else
      call s:current_preview.close()
    endif
  endif
endfunction
