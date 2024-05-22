let s:kind = luis#kind#tag#import()

function! s:test_action_open() abort
  call s:do_test_open('', 'open', {})
  call s:do_test_open(':E37:', 'open', {
  \   '&bufhidden': 'unload',
  \   '&modified': 1,
  \ })
endfunction

function! s:test_action_open__invalid_tag() abort
  let winnr = winnr()

  let Action = s:kind.action_table.open
  let candidate = { 'word': 'VIM' }
  call s:assert_exception(':E433:', { -> Action(candidate, {}) })

  if exists('*settagstack')
    call settagstack(winnr, { 'curidx': 1, 'items': [], 'length': 0 })
    call assert_equal(
    \   { 'curidx': 1, 'items': [], 'length': 0 },
    \   gettagstack(winnr)
    \ )
  endif
endfunction

function! s:test_action_open_x() abort
  call s:do_test_open('', 'open!', {})
  call s:do_test_open('', 'open!', {
  \   '&bufhidden': 'unload',
  \   '&modified': 1,
  \ })
endfunction

function! s:test_action_open_x__invalid_tag() abort
  let winnr = winnr()

  let Action = s:kind.action_table['open!']
  let candidate = { 'word': 'VIM' }
  call s:assert_exception(':E433:', { -> Action(candidate, {}) })

  if exists('*settagstack')
    call settagstack(winnr, { 'curidx': 1, 'items': [], 'length': 0 })
    call assert_equal(
    \   { 'curidx': 1, 'items': [], 'length': 0 },
    \   gettagstack(winnr)
    \ )
  endif
endfunction

function! s:test_kind_definition() abort
  call luis#_validate_kind(s:kind)
  call assert_equal('tag', s:kind.name)
endfunction

function! s:do_test_open(expected_exception, action_name, buf_options) abort
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
    let candidate = { 'word': 'vimtutor' }
    if a:expected_exception != ''
      call s:assert_exception(a:expected_exception, { -> Action(candidate, {}) })
      call assert_equal(bufnr, bufnr('%'))
    else
      silent call Action(candidate, {})
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

function! s:assert_exception(expected_message, callback)
  try
    silent call a:callback()
    call assert_true(0, 'Function must throw an exception')
  catch
    call assert_exception(a:expected_message)
  endtry
endfunction
