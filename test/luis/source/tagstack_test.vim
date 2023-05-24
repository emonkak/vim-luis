function! s:test_gather_candidates() abort
  if !exists('*gettagstack')
    return 'gettagstack() function is required.'
  endif

  let original_cwd = getcwd()
  cd $VIMRUNTIME/doc

  let window = win_getid()
  let tag_bufnrs = []

  call assert_equal(
  \   { 'curidx': 1, 'items': [], 'length': 0 },
  \   gettagstack(window)
  \ )

  silent tag! usr_01.txt
  let bufnr_1 = bufnr('%')

  silent tag! usr_02.txt
  let bufnr_2 = bufnr('%')

  silent tag! usr_03.txt
  let bufnr_3 = bufnr('%')

  try
    let source = luis#source#tagstack#new(window)

    call source.on_source_enter({})

    let candidates = source.gather_candidates({})
    call assert_equal([
    \   {
    \     'word': 'usr_01.txt',
    \     'menu': 'usr_01.txt:1:1',
    \     'user_data': {
    \       'buffer_nr': bufnr_1,
    \       'buffer_pos': [1, 1],
    \       'tagstack_index': 1,
    \     },
    \     'dup': 1,
    \     'luis_sort_priority': 1,
    \   },
    \   {
    \     'word': 'usr_02.txt',
    \     'menu': 'usr_01.txt:1:1',
    \     'user_data': {
    \       'buffer_nr': bufnr_1,
    \       'buffer_pos': [1, 1],
    \       'tagstack_index': 2,
    \     },
    \     'dup': 1,
    \     'luis_sort_priority': 2,
    \   },
    \   {
    \     'word': 'usr_03.txt',
    \     'menu': 'usr_02.txt:1:1',
    \     'user_data': {
    \       'buffer_nr': bufnr_2,
    \       'buffer_pos': [1, 1],
    \       'tagstack_index': 3,
    \     },
    \     'dup': 1,
    \     'luis_sort_priority': 3,
    \   }
    \ ], candidates)

    call settagstack(window, { 'curidx': 1, 'items': [], 'length': 0 })
    call assert_equal(
    \   { 'curidx': 1, 'items': [], 'length': 0 },
    \   gettagstack(window)
    \ )
  finally
    silent execute 'bwipeout' bufnr_1 bufnr_2 bufnr_3
    cd `=original_cwd`
  endtry
endfunction

function! s:test_preview_candidate() abort
  let source = luis#source#tagstack#new(win_getid())

  let candidate = {
  \  'word': '',
  \  'user_data': { 'buffer_nr': 123, 'buffer_pos': [2, 1]  },
  \ }
  call assert_equal(
  \   { 'type': 'buffer', 'bufnr': 123, 'pos': [2, 1] },
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
  let source = luis#source#tagstack#new(win_getid())
  call assert_equal(1, luis#validations#validate_source(source))
  call assert_equal('tagstack', source.name)
endfunction
