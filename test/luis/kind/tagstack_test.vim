let s:kind = luis#kind#tagstack#import()

function! s:test_action_open() abort
  if !exists('*settagstack')
    return 'settagstack() function is required.'
  endif
  call s:do_test_open(0, 'open', {})
  call s:do_test_open('Vim(buffer):E37:', 'open', {
  \   '&bufhidden': 'unload',
  \   '&modified': 1,
  \ })
endfunction

function! s:test_action_open_x() abort
  if !exists('*settagstack')
    return 'settagstack() function is required.'
  endif
  call s:do_test_open(0, 'open!', {})
  call s:do_test_open(0, 'open!', {
  \   '&bufhidden': 'unload',
  \   '&modified': 1,
  \ })
endfunction

function! s:test_kind_definition() abort
  call assert_true(luis#validations#validate_kind(s:kind))
  call assert_equal('tagstack', s:kind.name)
endfunction

function! s:do_test_open(expected_result, action_name, buf_options) abort
  let original_cwd = getcwd()
  cd $VIMRUNTIME/doc

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

  new
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
      silent let _ = Action(candidate, context)
      if type(a:expected_result) is v:t_string
        call assert_match(a:expected_result, _)
        call assert_equal(bufnr, bufnr('%'))
      else
        call assert_equal(a:expected_result, _)
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
    silent %bwipeout!
    cd `=original_cwd`
  endtry
endfunction
