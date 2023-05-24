function! s:test_gather_candidates() abort
  let original_oldfiles = v:oldfiles

  let cwd = getcwd()
  let v:oldfiles = [
  \   cwd . '/test/data/files/file1',
  \   cwd . '/test/data/files/link1',
  \   cwd . '/test/data/files/dir1/file2',
  \ ]

  try
    let source = luis#source#oldfiles#new()

    call source.on_source_enter({})

    let candidates = source.gather_candidates({})
    call assert_equal([
    \   {
    \     'word': 'test/data/files/file1',
    \     'user_data': { 'file_path': cwd . '/test/data/files/file1' },
    \     'luis_sort_priority': 0
    \   },
    \   {
    \     'word': 'test/data/files/link1',
    \     'user_data': { 'file_path': cwd . '/test/data/files/link1' },
    \     'luis_sort_priority': 1
    \   },
    \   {
    \     'word': 'test/data/files/dir1/file2',
    \     'user_data': { 'file_path': cwd . '/test/data/files/dir1/file2' },
    \     'luis_sort_priority': 2,
    \   },
    \ ], candidates)
  finally
    let v:oldfiles = original_oldfiles
  endtry
endfunction

function! s:test_preview_candidate() abort
  let source = luis#source#file#new()
  let context = {
  \   'preview_dimensions': { 'row': 0, 'col': 0, 'width': 80, 'height': 20 },
  \ }

  let candidate = {
  \  'word': 'test/data/file1',
  \  'kind': 'file',
  \  'user_data': { 'file_path': getcwd() . '/test/data/files/file1'  },
  \ }
  call assert_equal(
  \   { 'type': 'text', 'lines': ['file1'] },
  \   source.preview_candidate(candidate, context)
  \ )

  let candidate = {
  \  'word': 'test/data/file1',
  \  'kind': 'file',
  \  'user_data': {},
  \ }
  call assert_equal(
  \   { 'type': 'none' },
  \   source.preview_candidate(candidate, context)
  \ )
endfunction

function! s:test_source_definition() abort
  let source = luis#source#oldfiles#new()
  call assert_equal(1, luis#validations#validate_source(source))
  call assert_equal('oldfiles', source.name)
endfunction
