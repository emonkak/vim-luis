function! s:test_gather_candidates() abort
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
    \     'user_data': {
    \       'file_path': cwd . '/test/data/files/file1',
    \       'preview_path': cwd . '/test/data/files/file1',
    \     },
    \     'luis_sort_priority': 0,
    \   },
    \   {
    \     'word': 'test/data/files/link1',
    \     'user_data': {
    \       'file_path': cwd . '/test/data/files/link1',
    \       'preview_path': cwd . '/test/data/files/link1',
    \     },
    \     'luis_sort_priority': -1,
    \   },
    \   {
    \     'word': 'test/data/files/dir1/file2',
    \     'user_data': {
    \       'file_path': cwd . '/test/data/files/dir1/file2',
    \       'preview_path': cwd . '/test/data/files/dir1/file2',
    \     },
    \     'luis_sort_priority': -2,
    \   },
    \ ], candidates)
  finally
    let v:oldfiles = []
  endtry
endfunction

function! s:test_source_definition() abort
  let source = luis#source#oldfiles#new()
  call assert_true(luis#validations#validate_source(source))
  call assert_equal('oldfiles', source.name)
endfunction
