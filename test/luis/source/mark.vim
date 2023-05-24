function! s:test_gather_candidates__global() abort
  if !exists('*getmarklist')
    return 'getmarklist() function is required.'
  endif

  let bufname = tempname()
  silent edit `=bufname`
  let bufnr = bufnr('%')
  call setline(1, range(1, 100))

  delmarks!
  normal 1ggmA
  normal 20ggmB
  normal 40ggmC

  try
    let source = luis#source#mark#new()

    call source.on_source_enter({})

    let candidates = source.gather_candidates({})
    call assert_equal([
    \   {
    \     'word': bufname . ':1:1',
    \     'menu': 'mark A',
    \     'user_data': { 
    \       'mark_name': 'A',
    \       'mark_pos': [1, 1],
    \     },
    \     'dup': 1,
    \     'luis_sort_priority': char2nr('A'),
    \   },
    \   {
    \     'word': bufname . ':20:1',
    \     'menu': 'mark B',
    \     'user_data': { 
    \       'mark_name': 'B',
    \       'mark_pos': [20, 1],
    \     },
    \     'dup': 1,
    \     'luis_sort_priority': char2nr('B'),
    \   },
    \   {
    \     'word': bufname . ':40:1',
    \     'menu': 'mark C',
    \     'user_data': { 
    \       'mark_name': 'C',
    \       'mark_pos': [40, 1],
    \     },
    \     'dup': 1,
    \     'luis_sort_priority': char2nr('C'),
    \   },
    \ ], candidates)
  finally
    execute bufnr 'bwipeout!'
    delmarks A-Z
  endtry
endfunction

function! s:test_gather_candidates__local() abort
  if !exists('*getmarklist')
    return 'getmarklist() function is required.'
  endif

  let bufname = tempname()
  silent edit `=bufname`
  let bufnr = bufnr('%')
  call setline(1, range(1, 100))

  delmarks!
  normal 1ggma
  normal 20ggmb
  normal 40ggmc

  try
    let source = luis#source#mark#new(bufnr)

    call source.on_source_enter({})

    let candidates = source.gather_candidates({})
    call assert_equal([
    \   {
    \     'word': bufname . ':1:1',
    \     'menu': 'mark a',
    \     'user_data': { 
    \       'mark_name': 'a',
    \       'mark_pos': [1, 1],
    \     },
    \     'dup': 1,
    \     'luis_sort_priority': char2nr('a'),
    \   },
    \   {
    \     'word': bufname . ':20:1',
    \     'menu': 'mark b',
    \     'user_data': { 
    \       'mark_name': 'b',
    \       'mark_pos': [20, 1],
    \     },
    \     'dup': 1,
    \     'luis_sort_priority': char2nr('b'),
    \   },
    \   {
    \     'word': bufname . ':40:1',
    \     'menu': 'mark c',
    \     'user_data': { 
    \       'mark_name': 'c',
    \       'mark_pos': [40, 1],
    \     },
    \     'dup': 1,
    \     'luis_sort_priority': char2nr('c'),
    \   },
    \   {
    \     'word': bufname . ':20:1',
    \     'menu': "mark '",
    \     'user_data': { 
    \       'mark_name': "'",
    \       'mark_pos': [20, 1],
    \     },
    \     'dup': 1,
    \     'luis_sort_priority': char2nr("'"),
    \   },
    \   {
    \     'word': bufname . ':1:1',
    \     'menu': 'mark "',
    \     'user_data': { 
    \       'mark_name': '"',
    \       'mark_pos': [1, 1],
    \     },
    \     'dup': 1,
    \     'luis_sort_priority': char2nr('"'),
    \   }
    \ ], candidates)
  finally
    execute bufnr 'bwipeout!'
  endtry
endfunction

function! s:test_preview_candidate__global() abort
  let source = luis#source#mark#new()

  let candidate = {
  \  'word': 'foo:2:4',
  \  'user_data': { 'mark_name': 'a', 'mark_pos': [1, 1]  },
  \ }
  call assert_equal(
  \   { 'type': 'none' },
  \   source.preview_candidate(candidate, {})
  \ )

  let candidate = {
  \  'word': 'foo:2:4',
  \  'user_data': {},
  \ }
  call assert_equal(
  \   { 'type': 'none' },
  \   source.preview_candidate(candidate, {})
  \ )
endfunction

function! s:test_preview_candidate__local() abort
  let source = luis#source#mark#new(123)

  let candidate = {
  \  'word': 'foo:2:4',
  \  'user_data': { 'mark_name': 'a', 'mark_pos': [2, 1]  },
  \ }
  call assert_equal(
  \   { 'type': 'buffer', 'bufnr': 123, 'lnum': 2 },
  \   source.preview_candidate(candidate, {})
  \ )

  let candidate = {
  \  'word': 'foo:2:4',
  \  'user_data': {},
  \ }
  call assert_equal(
  \   { 'type': 'none' },
  \   source.preview_candidate(candidate, {})
  \ )
endfunction

function! s:test_source_definition() abort
  let source = luis#source#mark#new()
  call assert_equal(1, luis#validations#validate_source(source))
  call assert_equal('mark', source.name)
endfunction
