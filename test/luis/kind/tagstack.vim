let s:kind = g:luis#kind#tagstack#export

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
  call assert_equal('tagstack', s:kind.name)
  call assert_equal(type(s:kind.action_table), v:t_dict)
  call assert_equal(type(s:kind.key_table), v:t_dict)
  call assert_equal(s:kind.prototype, g:luis#kind#buffer#export)
endfunction

function! s:do_test_open(expected_result, action_name, buf_options) abort
  cd $VIMRUNTIME/doc

  let tag_bufnrs = []

  silent tag! usr_01.txt
  call add(tag_bufnrs, bufnr('%'))

  silent tag! usr_02.txt
  call add(tag_bufnrs, bufnr('%'))

  silent tag! usr_03.txt
  call add(tag_bufnrs, bufnr('%'))

  enew!
  let bufnr = bufnr('%')
  for [key, value] in items(a:buf_options)
    call setbufvar(bufnr, key, value)
  endfor

  try
    for i in range(len(tag_bufnrs))
      let tag_bufnr = tag_bufnrs[i]
      silent let _ = luis#do_action(s:kind, a:action_name, {
      \   'word': '',
      \   'user_data': {
      \     'buffer_nr': tag_bufnr,
      \     'tagstack_index': i + 1
      \   },
      \ })
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
  finally
    silent execute bufnr 'bwipeout!'
    for tag_bufnr in tag_bufnrs
      silent execute tag_bufnr 'bwipeout!'
    endfor
    cd -
  endtry
endfunction
