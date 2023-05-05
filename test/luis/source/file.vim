function s:test_gather_candidates() abort
  let original_cwd = getcwd()
  let new_cwd = original_cwd . '/test/data/files'
  cd `=new_cwd`
  call assert_equal(new_cwd, getcwd())

  try
    let source = luis#source#file#new()

    call assert_equal([
    \   { 'word': 'dir1', 'abbr': 'dir1/', 'kind': 'dir', 'user_data': { 'file_path': new_cwd . '/dir1/' } },
    \   { 'word': 'file1', 'abbr': 'file1', 'kind': 'file', 'user_data': { 'file_path': new_cwd . '/file1' } },
    \   { 'word': 'link1', 'abbr': 'link1', 'kind': 'link', 'user_data': { 'file_path': new_cwd . '/link1' } },
    \ ], source.gather_candidates({ 'pattern': '' }))

    call assert_equal([
    \   { 'word': 'dir1', 'abbr': 'dir1/', 'kind': 'dir', 'user_data': { 'file_path': new_cwd . '/dir1/' } },
    \   { 'word': 'file1', 'abbr': 'file1', 'kind': 'file', 'user_data': { 'file_path': new_cwd . '/file1' } },
    \   { 'word': 'link1', 'abbr': 'link1', 'kind': 'link', 'user_data': { 'file_path': new_cwd . '/link1' } },
    \   { 'word': 'dir1', 'kind': '*new*', 'user_data': {}, 'luis_sort_priority': 1 },
    \ ], source.gather_candidates({ 'pattern': 'dir1' }))

    call assert_equal([
    \   {  'word': 'dir1/dir2', 'abbr': 'dir1/dir2/', 'kind': 'dir', 'user_data': { 'file_path': new_cwd . '/dir1/dir2/' } },
    \   { 'word': 'dir1/file2', 'abbr': 'dir1/file2', 'kind': 'file', 'user_data': { 'file_path': new_cwd . '/dir1/file2' } },
    \   { 'word': 'dir1/link2', 'abbr': 'dir1/link2/', 'kind': 'dir', 'user_data': { 'file_path': new_cwd . '/dir1/link2/' } },
    \ ], source.gather_candidates({ 'pattern': 'dir1/' }))

    call assert_equal([
    \   { 'word': '.dir1', 'abbr': '.dir1/', 'kind': 'dir', 'user_data': { 'file_path': new_cwd . '/.dir1/' } },
    \   { 'word': '.file1', 'abbr': '.file1', 'kind': 'file', 'user_data': { 'file_path': new_cwd . '/.file1' } },
    \   { 'word': 'dir1', 'abbr': 'dir1/', 'kind': 'dir', 'user_data': { 'file_path': new_cwd . '/dir1/' } },
    \   { 'word': 'file1', 'abbr': 'file1', 'kind': 'file', 'user_data': { 'file_path': new_cwd . '/file1' } },
    \   { 'word': 'link1', 'abbr': 'link1', 'kind': 'link', 'user_data': { 'file_path': new_cwd . '/link1' } },
    \ ], source.gather_candidates({ 'pattern': '.' }))

    call assert_equal([
    \   { 'word': '.dir1', 'abbr': '.dir1/', 'kind': 'dir', 'user_data': { 'file_path': new_cwd . '/.dir1/' } },
    \   { 'word': '.file1', 'abbr': '.file1', 'kind': 'file', 'user_data': { 'file_path': new_cwd . '/.file1' } },
    \   { 'word': 'dir1', 'abbr': 'dir1/', 'kind': 'dir', 'user_data': { 'file_path': new_cwd . '/dir1/' } },
    \   { 'word': 'file1', 'abbr': 'file1', 'kind': 'file', 'user_data': { 'file_path': new_cwd . '/file1' } },
    \   { 'word': 'link1', 'abbr': 'link1', 'kind': 'link', 'user_data': { 'file_path': new_cwd . '/link1' } },
    \   { 'word': '.dir1', 'kind': '*new*', 'user_data': {}, 'luis_sort_priority': 1 },
    \ ], source.gather_candidates({ 'pattern': '.dir1' }))

    call assert_equal([
    \   { 'word': '.dir1/dir2', 'abbr': '.dir1/dir2/', 'kind': 'dir', 'user_data': { 'file_path': new_cwd . '/.dir1/dir2/' } },
    \   { 'word': '.dir1/file2', 'abbr': '.dir1/file2', 'kind': 'file', 'user_data': { 'file_path': new_cwd . '/.dir1/file2' } },
    \   { 'word': '.dir1/link2', 'abbr': '.dir1/link2/', 'kind': 'dir', 'user_data': { 'file_path': new_cwd . '/.dir1/link2/' } },
    \ ], source.gather_candidates({ 'pattern': '.dir1/' }))

    call assert_equal([
    \   { 'word': '.dir1/.dir2', 'abbr': '.dir1/.dir2/', 'kind': 'dir', 'user_data': { 'file_path': new_cwd . '/.dir1/.dir2/' } },
    \   { 'word': '.dir1/.file2', 'abbr': '.dir1/.file2', 'kind': 'file', 'user_data': { 'file_path': new_cwd . '/.dir1/.file2' } },
    \   { 'word': '.dir1/.link2', 'abbr': '.dir1/.link2/', 'kind': 'dir', 'user_data': { 'file_path': new_cwd . '/.dir1/.link2/' } },
    \   { 'word': '.dir1/dir2', 'abbr': '.dir1/dir2/', 'kind': 'dir', 'user_data': { 'file_path': new_cwd . '/.dir1/dir2/' } },
    \   { 'word': '.dir1/file2', 'abbr': '.dir1/file2', 'kind': 'file', 'user_data': { 'file_path': new_cwd . '/.dir1/file2' } },
    \   { 'word': '.dir1/link2', 'abbr': '.dir1/link2/', 'kind': 'dir', 'user_data': { 'file_path': new_cwd . '/.dir1/link2/' } },
    \ ], source.gather_candidates({ 'pattern': '.dir1/.' }))
  finally
    cd `=original_cwd`
    call assert_equal(original_cwd, getcwd())
  endtry
endfunction

function s:test_gather_candidates__home_directory() abort
  let old_HOME = $HOME
  let new_HOME = getcwd() . '/test/data/files'
  let $HOME = new_HOME

  try
    let source = luis#source#file#new()

    call source.on_source_enter()

    call assert_equal([
    \   { 'word': '~/dir1', 'abbr': '~/dir1/', 'kind': 'dir', 'user_data': { 'file_path': new_HOME . '/dir1/' } },
    \   { 'word': '~/file1', 'abbr': '~/file1', 'kind': 'file', 'user_data': { 'file_path': new_HOME . '/file1' } },
    \   { 'word': '~/link1', 'abbr': '~/link1', 'kind': 'link', 'user_data': { 'file_path': new_HOME . '/link1' } },
    \ ], source.gather_candidates({ 'pattern': '~/' }))

    call assert_equal([
    \   { 'word': '$HOME/dir1', 'abbr': '$HOME/dir1/', 'kind': 'dir', 'user_data': { 'file_path': new_HOME . '/dir1/' } },
    \   { 'word': '$HOME/file1', 'abbr': '$HOME/file1', 'kind': 'file', 'user_data': { 'file_path': new_HOME . '/file1' } },
    \   { 'word': '$HOME/link1', 'abbr': '$HOME/link1', 'kind': 'link', 'user_data': { 'file_path': new_HOME . '/link1' } },
    \ ], source.gather_candidates({ 'pattern': '$HOME/' }))

    call assert_equal([
    \   { 'word': '~/.dir1', 'abbr': '~/.dir1/', 'kind': 'dir', 'user_data': { 'file_path': new_HOME . '/.dir1/' } },
    \   { 'word': '~/.file1', 'abbr': '~/.file1', 'kind': 'file', 'user_data': { 'file_path': new_HOME . '/.file1' } },
    \   { 'word': '~/dir1', 'abbr': '~/dir1/', 'kind': 'dir', 'user_data': { 'file_path': new_HOME . '/dir1/' } },
    \   { 'word': '~/file1', 'abbr': '~/file1', 'kind': 'file', 'user_data': { 'file_path': new_HOME . '/file1' } },
    \   { 'word': '~/link1', 'abbr': '~/link1', 'kind': 'link', 'user_data': { 'file_path': new_HOME . '/link1' } },
    \ ], source.gather_candidates({ 'pattern': '~/.' }))

    call assert_equal([
    \   { 'word': '$HOME/.dir1', 'abbr': '$HOME/.dir1/', 'kind': 'dir', 'user_data': { 'file_path': new_HOME . '/.dir1/' } },
    \   { 'word': '$HOME/.file1', 'abbr': '$HOME/.file1', 'kind': 'file', 'user_data': { 'file_path': new_HOME . '/.file1' } },
    \   { 'word': '$HOME/dir1', 'abbr': '$HOME/dir1/', 'kind': 'dir', 'user_data': { 'file_path': new_HOME . '/dir1/' } },
    \   { 'word': '$HOME/file1', 'abbr': '$HOME/file1', 'kind': 'file', 'user_data': { 'file_path': new_HOME . '/file1' } },
    \   { 'word': '$HOME/link1', 'abbr': '$HOME/link1', 'kind': 'link', 'user_data': { 'file_path': new_HOME . '/link1' } },
    \ ], source.gather_candidates({ 'pattern': '$HOME/.' }))

    call source.on_source_leave()
  finally
    let $HOME = old_HOME
  endtry
endfunction

function s:test_is_special_char() abort
  let source = luis#source#file#new()
  let separator = exists('+shellslash') && !&shellslash ? '\' : '/'

  call assert_true(source.is_special_char(separator))
  call assert_false(source.is_special_char('A'))
endfunction

function s:test_is_valid_for_acc() abort
  let source = luis#source#file#new()

  call assert_false(source.is_valid_for_acc({
  \   'word': '',
  \   'kind': 'file',
  \ }))
  call assert_true(source.is_valid_for_acc({
  \   'word': '',
  \   'kind': 'dir',
  \ }))
  call assert_false(source.is_valid_for_acc({
  \   'word': '',
  \   'kind': 'link',
  \ }))
endfunction

function s:test_on_action() abort
  let cwd = getcwd()
  let source = luis#source#file#new()

  let candidate = { 'word': 'test.vim', 'user_data': {} }
  call source.on_action(candidate)
  call assert_equal({
  \   'word': 'test.vim',
  \   'user_data': { 'file_path': cwd . '/test.vim' },
  \ }, candidate)

  let candidate = { 'word': '~/.vimrc', 'user_data': {} }
  call source.on_action(candidate)
  call assert_equal({
  \   'word': '~/.vimrc',
  \   'user_data': { 'file_path': $HOME . '/.vimrc' },
  \ }, candidate)

  let candidate = { 'word': '$HOME/.vimrc', 'user_data': {} }
  call source.on_action(candidate)
  call assert_equal({
  \   'word': '$HOME/.vimrc',
  \   'user_data': { 'file_path': $HOME . '/.vimrc' },
  \ }, candidate)
endfunction

function s:test_source_definition() abort
  let source = luis#source#file#new()
  let schema = luis#_scope().SCHEMA_SOURCE
  let errors = luis#schema#validate(schema, source)
  call assert_equal([], errors)
  call assert_equal('file', source.name)
endfunction
