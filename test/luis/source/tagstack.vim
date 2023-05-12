function! s:test_gather_candidates() abort
  if !exists('*gettagstack')
    return 'gettagstack() function is required.'
  endif

  let original_cwd = getcwd()
  cd $VIMRUNTIME/doc

  let winnr = winnr()
  let tag_bufnrs = []

  call assert_equal(
  \   { 'curidx': 1, 'items': [], 'length': 0 },
  \   gettagstack(winnr)
  \ )

  silent tag! usr_01.txt
  let bufnr_1 = bufnr('%')

  silent tag! usr_02.txt
  let bufnr_2 = bufnr('%')

  silent tag! usr_03.txt
  let bufnr_3 = bufnr('%')

  new

  try
    let source = luis#source#tagstack#new()

    call source.on_source_enter({})

    let candidates = source.gather_candidates({})
    call assert_equal([
    \   {
    \     'word': 'usr_01.txt',
    \     'menu': 'usr_01.txt:1:1',
    \     'user_data': {
    \       'buffer_nr': bufnr_1,
    \       'tagstack_index': 1,
    \       'buffer_pos': [bufnr_1, 1, 1, 0],
    \     },
    \     'dup': 1,
    \     'luis_sort_priority': 1,
    \   },
    \   {
    \     'word': 'usr_02.txt',
    \     'menu': 'usr_01.txt:1:1',
    \     'user_data': {
    \       'buffer_nr': bufnr_1,
    \       'tagstack_index': 2,
    \       'buffer_pos': [bufnr_1, 1, 1, 0],
    \     },
    \     'dup': 1,
    \     'luis_sort_priority': 2,
    \   },
    \   {
    \     'word': 'usr_03.txt',
    \     'menu': 'usr_02.txt:1:1',
    \     'user_data': {
    \       'buffer_nr': bufnr_2,
    \       'tagstack_index': 3,
    \       'buffer_pos': [bufnr_2, 1, 1, 0],
    \     },
    \     'dup': 1,
    \     'luis_sort_priority': 3,
    \   }
    \ ], candidates)

    call settagstack(winnr, { 'curidx': 1, 'items': [], 'length': 0 })
    call assert_equal(
    \   { 'curidx': 1, 'items': [], 'length': 0 },
    \   gettagstack(winnr)
    \ )
  finally
    silent %bwipeout
    cd `=original_cwd`
  endtry
endfunction

function! s:test_source_definition() abort
  let source = luis#source#tagstack#new()
  let errors = luis#_validate_source(source)
  call assert_equal([], errors)
  call assert_equal('tagstack', source.name)
endfunction
