function! s:test_close() abort
  let previewer = luis#previewer#null#import()
  call previewer.close()
endfunction

function! s:test_definition() abort
  let previewer = luis#previewer#null#import()
  call assert_true(luis#_validate_previewer(previewer))
endfunction

function! s:test_bounds() abort
  let previewer = luis#previewer#null#import()
  call assert_equal(
  \   { 'row': 0, 'col': 0, 'width': 0, 'height': 0 },
  \   previewer.bounds()
  \ )
endfunction

function! s:test_is_active() abort
  let previewer = luis#previewer#null#import()
  call assert_false(previewer.is_active())
endfunction

function! s:test_open_buffer() abort
  let previewer = luis#previewer#null#import()
  call previewer.open_buffer(
  \   123,
  \   { 'row': 0, 'col': 0, 'width': 0, 'height': 0 },
  \   {}
  \ )
endfunction

function! s:test_open_text() abort
  let previewer = luis#previewer#null#import()
  call previewer.open_text(
  \   ['foo'],
  \   { 'row': 0, 'col': 0, 'width': 0, 'height': 0 },
  \   {}
  \ )
endfunction
