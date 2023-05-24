silent runtime! test/mocks.vim
silent runtime! test/spy.vim

function! s:test_guess_candidate__from_completed_item() abort
  let kind = CreateMockKind()
  let matcher = CreateMockMatcher()
  let source = CreateMockSource(kind, matcher, [])
  let session = luis#ui#pmenu#new_session(source, {})

  try
    let candidate = { 'word': 'VIM', 'user_data': {} }
    let v:completed_item = candidate
    call assert_equal(candidate, session.guess_candidate())

    " Decode user_data as JSON if it is a string.
    let candidate = { 'word': 'VIM', 'user_data': { 'file_path': '/VIM' } }
    let v:completed_item = { 'word': 'VIM', 'user_data': '{"file_path": "/VIM"}' }
    call assert_equal(candidate, session.guess_candidate())
  catch 'Vim(let):E46:'
    return 'v:completed_item must be writable.'
  endtry

  let v:completed_item = {}
endfunction

function! s:test_guess_candidate__from_first_candidate() abort
  let kind = CreateMockKind()
  let matcher = CreateMockMatcher()
  let source = CreateMockSource(kind, matcher, [])
  let session = luis#ui#pmenu#new_session(source, {})

  call assert_false(session.is_active())

  let original_bufnr = bufnr('%')
  call session.start()
  let ui_bufnr = bufnr('%')

  try
    call assert_notequal(original_bufnr, ui_bufnr)
    call assert_equal('A', s:consume_keys())
    call assert_equal('luis-pmenu', &l:filetype)
    call assert_equal(['Source: mock_source', '>'], getline(1, line('$')))
    call assert_equal(2, winnr('$'))
    call assert_equal(1, winnr())
    call assert_true(session.is_active())

    let session.last_candidates = [
    \   { 'word': 'foo' },
    \   { 'word': 'bar' },
    \   { 'word': 'baz' },
    \ ]
    let session.last_pattern_raw = '>'

    call assert_equal(session.last_candidates[0], session.guess_candidate())

    call session.quit()

    call assert_notequal('luis-pmenu', &l:filetype)
    call assert_equal(original_bufnr, bufnr('%'))
    call assert_equal(1, winnr('$'))
    call assert_equal(1, winnr())
    call assert_false(session.is_active())
  finally
    execute ui_bufnr 'bwipeout!' 
  endtry
endfunction

function! s:test_guess_candidate__from_selected_candidate() abort
  let kind = CreateMockKind()
  let matcher = CreateMockMatcher()
  let source = CreateMockSource(kind, matcher, [])
  let session = luis#ui#pmenu#new_session(source, {})

  call assert_false(session.is_active())

  let original_bufnr = bufnr('%')
  call session.start()
  let ui_bufnr = bufnr('%')

  try
    call assert_notequal(original_bufnr, ui_bufnr)
    call assert_equal('A', s:consume_keys())
    call assert_equal('luis-pmenu', &l:filetype)
    call assert_equal(['Source: mock_source', '>'], getline(1, line('$')))
    call assert_equal(2, winnr('$'))
    call assert_equal(1, winnr())
    call assert_true(session.is_active())

    let session.last_candidates = [
    \   { 'word': 'foo' },
    \   { 'word': 'bar' },
    \   { 'word': 'baz' },
    \ ]
    call setline(line('.'), 'bar')

    call assert_equal(session.last_candidates[1], session.guess_candidate())

    call session.quit()

    call assert_notequal('luis-pmenu', &l:filetype)
    call assert_equal(original_bufnr, bufnr('%'))
    call assert_equal(1, winnr('$'))
    call assert_equal(1, winnr())
    call assert_false(session.is_active())
  finally
    execute ui_bufnr 'bwipeout!' 
  endtry
endfunction

function! s:test_guess_candidate__from_default_candidate() abort
  let kind = CreateMockKind()
  let matcher = CreateMockMatcher()
  let source = CreateMockSource(kind, matcher, [])
  let session = luis#ui#pmenu#new_session(source, {})

  call assert_false(session.is_active())

  let original_bufnr = bufnr('%')
  call session.start()
  let ui_bufnr = bufnr('%')

  try
    call assert_notequal(original_bufnr, ui_bufnr)
    call assert_equal('A', s:consume_keys())
    call assert_equal('luis-pmenu', &l:filetype)
    call assert_equal(['Source: mock_source', '>'], getline(1, line('$')))
    call assert_equal(2, winnr('$'))
    call assert_equal(1, winnr())
    call assert_true(session.is_active())

    let session.last_candidates = []
    let session.last_pattern_raw = '>VIM'
    call setline(line('.'), '>VIM')

    call assert_equal({ 'word': 'VIM', 'user_data': {} }, session.guess_candidate())

    call session.quit()

    call assert_notequal('luis-pmenu', &l:filetype)
    call assert_equal(original_bufnr, bufnr('%'))
    call assert_equal(1, winnr('$'))
    call assert_equal(1, winnr())
    call assert_false(session.is_active())
  finally
    execute ui_bufnr 'bwipeout!' 
  endtry
endfunction

function! s:test_reload_candidates() abort
  let kind = CreateMockKind()
  let matcher = CreateMockMatcher()
  let source = CreateMockSource(kind, matcher, [])
  let [session, session_spies] = SpyDict(luis#ui#pmenu#new_session(source, {}))

  call assert_false(session.is_active())

  let original_bufnr = bufnr('%')
  call session.start()
  let ui_bufnr = bufnr('%')

  try
    call assert_notequal(original_bufnr, ui_bufnr)
    call assert_equal('A', s:consume_keys())
    call assert_equal('luis-pmenu', &l:filetype)
    call assert_equal(['Source: mock_source', '>'], getline(1, line('$')))
    call assert_equal(2, winnr('$'))
    call assert_equal(1, winnr())
    call assert_true(session.is_active())

    function! s:on_CompleteDone() abort closure
      call session.reload_candidates()
      call assert_equal("\<C-x>", nr2char(getchar(0)))
      call assert_equal("\<C-o>", nr2char(getchar(0)))
    endfunction

    autocmd! CompleteDone <buffer>  call s:on_CompleteDone()

    normal! A

    call assert_equal(1, session_spies.reload_candidates.call_count())

    call session.quit()

    call assert_notequal('luis-pmenu', &l:filetype)
    call assert_equal(original_bufnr, bufnr('%'))
    call assert_equal(1, winnr('$'))
    call assert_equal(1, winnr())
    call assert_false(session.is_active())
  finally
    execute ui_bufnr 'bwipeout!' 
  endtry
endfunction

function! s:test_start__without_options() abort
  let kind = CreateMockKind()
  let matcher = CreateMockMatcher()
  let source = CreateMockSource(kind, matcher, [])
  let session = luis#ui#pmenu#new_session(source)

  call assert_false(session.is_active())

  let original_bufnr = bufnr('%')
  call session.start()
  let ui_bufnr = bufnr('%')

  try
    call assert_notequal(original_bufnr, ui_bufnr)
    call assert_equal('A', s:consume_keys())
    call assert_equal('luis-pmenu', &l:filetype)
    call assert_equal(['Source: mock_source', '>'], getline(1, line('$')))
    call assert_equal(2, winnr('$'))
    call assert_equal(1, winnr())
    call assert_true(session.is_active())

    call session.quit()

    call assert_notequal('luis-pmenu', &l:filetype)
    call assert_equal(original_bufnr, bufnr('%'))
    call assert_equal(1, winnr('$'))
    call assert_equal(1, winnr())
    call assert_false(session.is_active())


    " Reuse the existing luis buffer.
    call session.start()

    call assert_equal('A', s:consume_keys())
    call assert_equal(ui_bufnr, bufnr('%'))
    call assert_equal('luis-pmenu', &l:filetype)
    call assert_equal(['Source: mock_source', '>'], getline(1, line('$')))
    call assert_equal(2, winnr('$'))
    call assert_equal(1, winnr())
    call assert_true(session.is_active())

    call session.quit()

    call assert_notequal('luis-pmenu', &l:filetype)
    call assert_equal(original_bufnr, bufnr('%'))
    call assert_equal(1, winnr('$'))
    call assert_equal(1, winnr())
    call assert_false(session.is_active())

    " Start after unload the existing luis buffer.
    call session.start()

    call assert_equal('A', s:consume_keys())
    call assert_equal(ui_bufnr, bufnr('%'))
    call assert_equal('luis-pmenu', &l:filetype)
    call assert_equal(['Source: mock_source', '>'], getline(1, line('$')))
    call assert_equal(2, winnr('$'))
    call assert_equal(1, winnr())
    call assert_true(session.is_active())

    call session.quit()

    call assert_notequal('luis-pmenu', &l:filetype)
    call assert_equal(original_bufnr, bufnr('%'))
    call assert_equal(1, winnr('$'))
    call assert_equal(1, winnr())
    call assert_false(session.is_active())
  finally
    execute ui_bufnr 'bwipeout!' 
  endtry
endfunction

function! s:test_start__with_options() abort
  let kind = CreateMockKind()
  let matcher = CreateMockMatcher()
  let source = CreateMockSource(kind, matcher, [])
  let session = luis#ui#pmenu#new_session(source, {
  \   'initial_pattern': 'VIM',
  \ })

  call assert_false(session.is_active())

  let original_bufnr = bufnr('%')
  call session.start()
  let ui_bufnr = bufnr('%')

  try
    call assert_notequal(original_bufnr, ui_bufnr)
    call assert_equal('A', s:consume_keys())
    call assert_equal('luis-pmenu', &l:filetype)
    call assert_equal(['Source: mock_source', '>VIM'], getline(1, line('$')))
    call assert_equal(2, winnr('$'))
    call assert_equal(1, winnr())
    call assert_true(session.is_active())

    call session.quit()

    call assert_notequal('luis-pmenu', &l:filetype)
    call assert_equal(original_bufnr, bufnr('%'))
    call assert_equal(1, winnr('$'))
    call assert_equal(1, winnr())
    call assert_false(session.is_active())

    call session.start()

    " Reuse existing luis buffer.
    call assert_equal(ui_bufnr, bufnr('%'))
    call assert_equal('A', s:consume_keys())
    call assert_equal('luis-pmenu', &l:filetype)
    call assert_equal(['Source: mock_source', '>VIM'], getline(1, line('$')))
    call assert_equal(2, winnr('$'))
    call assert_equal(1, winnr())
    call assert_true(session.is_active())

    call session.quit()

    call assert_notequal('luis-pmenu', &l:filetype)
    call assert_equal(original_bufnr, bufnr('%'))
    call assert_equal(1, winnr('$'))
    call assert_equal(1, winnr())
    call assert_false(session.is_active())
  finally
    execute ui_bufnr 'bwipeout!' 
  endtry
endfunction

function! s:consume_keys() abort
  let keys = ''
  while 1
    let char = getchar(0)
    if char is 0
      break
    endif
    let keys .= nr2char(char)
  endwhile
  return keys
endfunction
