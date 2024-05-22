let s:kind = luis#kind#tagstack#import()

function! s:test_action_open() abort
  if !exists('*settagstack')
    return 'settagstack() function is required.'
  endif
  call s:do_test_open('', 'open', {})
  call s:do_test_open(':E37:', 'open', {
  \   '&bufhidden': 'unload',
  \   '&modified': 1,
  \ })
endfunction

function! s:test_action_open_x() abort
  if !exists('*settagstack')
    return 'settagstack() function is required.'
  endif
  call s:do_test_open('', 'open!', {})
  call s:do_test_open('', 'open!', {
  \   '&bufhidden': 'unload',
  \   '&modified': 1,
  \ })
endfunction

function! s:test_kind_definition() abort
  call luis#_validate_kind(s:kind)
  call assert_equal('tagstack', s:kind.name)
endfunction

function! s:do_test_open(expected_exception, action_name, buf_options) abort
  new
  lcd $VIMRUNTIME/doc

  let winnr = winnr()
  let tag_bufnrs = []

  call assert_equal(
  \   { 'curidx': 1, 'items': [], 'length': 0 },
  \   gettagstack(winnr)
  \ )

  silent tag! usr_01.txt
  call add(tag_bufnrs, bufnr('%'))

  silent tag! usr_02.txt
  call add(tag_bufnrs, bufnr('%'))

  silent tag! usr_03.txt
  call add(tag_bufnrs, bufnr('%'))

  let tagstack = gettagstack(winnr)
  call assert_equal(4, tagstack.curidx)
  call assert_equal(3, tagstack.length)

  enew
  let bufnr = bufnr('%')
  for [key, value] in items(a:buf_options)
    call setbufvar(bufnr, key, value)
  endfor

  try
    for i in range(len(tag_bufnrs))
      let tag_bufnr = tag_bufnrs[i]
      let Action = s:kind.action_table[a:action_name]
      let candidate = {
      \   'word': '',
      \   'user_data': {
      \     'buffer_nr': tag_bufnr,
      \     'tagstack_index': i + 1
      \   },
      \ }
      let context = {
      \   'kind': s:kind,
      \ }
      if a:expected_exception != ''
        call s:assert_exception(a:expected_exception, { -> Action(candidate, context) })
        call assert_equal(bufnr, bufnr('%'))
      else
        silent call Action(candidate, context)
        call assert_equal(tag_bufnr, bufnr('%'))
        call assert_equal(i + 1, gettagstack().curidx)
      endif
      silent execute bufnr 'buffer'
    endfor

    call settagstack(winnr, { 'curidx': 1, 'items': [], 'length': 0 })
    call assert_equal(
    \   { 'curidx': 1, 'items': [], 'length': 0 },
    \   gettagstack(winnr)
    \ )
  finally
    close!
    silent %bwipeout!
  endtry
endfunction

function! s:assert_exception(expected_message, callback)
  try
    silent call a:callback()
    call assert_true(0, 'Function must throw an exception')
  catch
    call assert_exception(a:expected_message)
  endtry
endfunction
