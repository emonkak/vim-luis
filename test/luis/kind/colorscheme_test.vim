let s:kind = luis#kind#colorscheme#import()

function! s:test_action_open() abort
  call assert_false(has_key(g:, 'colors_name'))
  let Action = s:kind.action_table.open
  silent call Action({ 'word': 'darkblue' }, {})
  call assert_equal('darkblue', g:colors_name)
  highlight clear
endfunction

function! s:test_action_open__invalid_colorscheme() abort
  let Action = s:kind.action_table.open
  call s:assert_exception(':E185', { -> Action({ 'word': 'XXX' }, {}) })
endfunction

function! s:test_kind_definition() abort
  call luis#_validate_kind(s:kind)
  call assert_equal('colorscheme', s:kind.name)
endfunction

function! s:assert_exception(expected_message, callback)
  try
    silent call a:callback()
    call assert_true(0, 'Function must throw an exception')
  catch
    call assert_exception(a:expected_message)
  endtry
endfunction
