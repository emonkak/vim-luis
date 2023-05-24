function! s:test_gather_candidates() abort
  if !exists('*settagstack')
    return 'settagstack() function is required.'
  endif

  let bufname = tempname()
  silent split `=bufname`
  let bufnr = bufnr('%')
  let window = win_getid()

  call setline(1, range(1, 100))
  clearjumps
  normal! 20gg
  normal! 40gg
  normal! 60gg
  normal! 80gg
  normal! 1gg

  try
    let source = luis#source#jumplist#new(window)

    call source.on_source_enter({})

    let candidates = source.gather_candidates({})
    call assert_equal([
    \   {
    \     'word': bufname . ':80:0',
    \     'menu': 'jump 1',
    \     'user_data': { 'buffer_nr': bufnr, 'buffer_pos': [80, 0] },
    \     'dup': 1,
    \     'luis_sort_priority': 1
    \   },
    \   {
    \     'word': bufname . ':60:0',
    \     'menu': 'jump 2',
    \     'user_data': { 'buffer_nr': bufnr, 'buffer_pos': [60, 0] },
    \     'dup': 1,
    \     'luis_sort_priority': 2
    \   },
    \   {
    \     'word': bufname . ':40:0',
    \     'menu': 'jump 3',
    \     'user_data': { 'buffer_nr': bufnr, 'buffer_pos': [40, 0] },
    \     'dup': 1,
    \     'luis_sort_priority': 3
    \   },
    \   {
    \     'word': bufname . ':20:0',
    \     'menu': 'jump 4',
    \     'user_data': { 'buffer_nr': bufnr, 'buffer_pos': [20, 0] },
    \     'dup': 1,
    \     'luis_sort_priority': 4
    \   },
    \   {
    \     'word': bufname . ':1:0',
    \     'menu': 'jump 5',
    \     'user_data': { 'buffer_nr': bufnr, 'buffer_pos': [1, 0] },
    \     'dup': 1,
    \     'luis_sort_priority': 5
    \   },
    \ ], candidates)
  finally
    execute bufnr 'bwipeout!'
  endtry
endfunction

function! s:test_preview_candidate() abort
  let source = luis#source#jumplist#new(win_getid())

  let candidate = {
  \  'word': '',
  \  'user_data': { 'buffer_nr': 123, 'buffer_pos': [1, 1]  },
  \ }
  call assert_equal(
  \   { 'type': 'buffer', 'bufnr': 123, 'lnum': 1 },
  \   source.preview_candidate(candidate, {})
  \ )

  let candidate = {
  \  'word': '',
  \  'user_data': { 'buffer_nr': 123 },
  \ }
  call assert_equal(
  \   { 'type': 'none' },
  \   source.preview_candidate(candidate, {})
  \ )

  let candidate = {
  \  'word': '',
  \  'user_data': {},
  \ }
  call assert_equal(
  \   { 'type': 'none' },
  \   source.preview_candidate(candidate, {})
  \ )
endfunction

function! s:test_source_definition() abort
  let source = luis#source#jumplist#new(win_getid())
  call assert_equal(1, luis#validations#validate_source(source))
  call assert_equal('jumplist', source.name)
endfunction
