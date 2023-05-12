let s:kind = luis#kind#colorscheme#import()

function! s:test_action_open() abort
  call assert_false(has_key(g:, 'colors_name'))
  let Action = s:kind.action_table.open
  let _ = Action({ 'word': 'darkblue' }, {})
  call assert_equal(0, _)
  call assert_equal('darkblue', g:colors_name)
  highlight clear
endfunction

function! s:test_action_open__invalid_colorscheme() abort
  let Action = s:kind.action_table.open
  silent let _ = Action({ 'word': 'XXX' }, {})
  call assert_match('Vim(colorscheme):E185:', _)
endfunction

function! s:test_kind_definition() abort
  call assert_equal([], luis#_validate_kind(s:kind))
  call assert_equal('colorscheme', s:kind.name)
endfunction
