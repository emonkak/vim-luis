let s:kind = g:luis#kind#colorscheme#export

function! s:test_action_open() abort
  call assert_false(has_key(g:, 'colors_name'))
  let _ = luis#do_action(s:kind, 'open', {
  \   'word': 'darkblue',
  \ })
  call assert_equal(0, _)
  call assert_equal('darkblue', g:colors_name)
  highlight clear
endfunction

function! s:test_action_open_invalid_colorscheme() abort
  silent let _ = luis#do_action(s:kind, 'open', {
  \   'word': '_',
  \ })
  call assert_match('Vim(colorscheme):E185:', _)
endfunction

function! s:test_kind_definition() abort
  call assert_equal('colorscheme', s:kind.name)
  call assert_true(type(s:kind.action_table), v:t_dict)
  call assert_true(type(s:kind.key_table), v:t_dict)
  call assert_equal(s:kind.prototype, g:luis#kind#common#export)
endfunction
