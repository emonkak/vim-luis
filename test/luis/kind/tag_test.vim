let s:kind = luis#kind#tag#import()

function! s:test_action_open() abort
  call s:do_test_open(0, 'open', {})
  call s:do_test_open('^E37:', 'open', {
  \   '&bufhidden': 'unload',
  \   '&modified': 1,
  \ })
endfunction

function! s:test_action_open__invalid_tag() abort
  let winnr = winnr()

  let Action = s:kind.action_table.open
  let _ = Action({ 'word': 'VIM' }, {})
  call assert_match('^E\%(426\|433\):', _)

  if exists('*settagstack')
    call settagstack(winnr, { 'curidx': 1, 'items': [], 'length': 0 })
    call assert_equal(
    \   { 'curidx': 1, 'items': [], 'length': 0 },
    \   gettagstack(winnr)
    \ )
  endif
endfunction

function! s:test_action_open_x() abort
  call s:do_test_open(0, 'open!', {})
  call s:do_test_open(0, 'open!', {
  \   '&bufhidden': 'unload',
  \   '&modified': 1,
  \ })
endfunction

function! s:test_action_open_x__invalid_tag() abort
  let winnr = winnr()

  let Action = s:kind.action_table['open!']
  let _ = Action({ 'word': 'VIM' }, {})
  call assert_match('^E\%(426\|433\):', _)

  if exists('*settagstack')
    call settagstack(winnr, { 'curidx': 1, 'items': [], 'length': 0 })
    call assert_equal(
    \   { 'curidx': 1, 'items': [], 'length': 0 },
    \   gettagstack(winnr)
    \ )
  endif
endfunction

function! s:test_kind_definition() abort
  call assert_true(luis#validate_kind(s:kind))
  call assert_equal('tag', s:kind.name)
endfunction

function! s:do_test_open(expected_result, action_name, buf_options) abort
  let original_cwd = getcwd()
  cd $VIMRUNTIME/doc

  silent edit `=tempname()`
  let bufnr = bufnr('%')
  for [key, value] in items(a:buf_options)
    call setbufvar(bufnr, key, value)
  endfor

  let winnr = winnr()

  try
    let Action = s:kind.action_table[a:action_name]
    silent let _ = Action({ 'word': 'vimtutor' }, {})
    if type(a:expected_result) is v:t_string
      call assert_match(a:expected_result, _)
      call assert_equal(bufnr, bufnr('%'))
    else
      call assert_equal(0, _)
      call assert_notequal(bufnr, bufnr('%'))
      call assert_match('\*vimtutor\*', getline('.'))
      silent bwipeout
    endif

    if exists('*settagstack')
      call settagstack(winnr, { 'curidx': 1, 'items': [], 'length': 0 })
      call assert_equal(
      \   { 'curidx': 1, 'items': [], 'length': 0 },
      \   gettagstack(winnr)
      \ )
    endif
  finally
    silent execute bufnr 'bwipeout!'
    cd `=original_cwd`
  endtry
endfunction
