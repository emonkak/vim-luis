silent runtime! test/mocks.vim
silent runtime! test/spy.vim

function! s:test_guess_candidate__from_completed_item() abort
  let finder = luis#finder#pmenu#new({})

  try
    let candidate = {
    \   'word': 'VIM',
    \   'user_data': {},
    \ }
    let v:completed_item = copy(candidate)
    call assert_equal(candidate, finder.guess_candidate())

    " Decode user_data as JSON if it is a string.
    let v:completed_item = { 'word': 'VIM', 'user_data': '{"file_path": "/VIM"}' }
    call assert_equal({
    \   'word': 'VIM',
    \   'user_data': { 'file_path': '/VIM' },
    \ }, finder.guess_candidate())
  catch 'Vim(let):E46:'
    return 'v:completed_item must be writable.'
  endtry

  let v:completed_item = {}
endfunction

function! s:test_guess_candidate__from_first_candidate() abort
  let finder = luis#finder#pmenu#new({})
  let session = luis#session#new(
  \   finder,
  \   CreateMockSource(),
  \   CreateMockMatcher(),
  \   CreateMockComparer(),
  \   CreateMockPreviewer(),
  \   CreateMockHook()
  \ )

  call assert_false(finder.is_active())

  let original_bufnr = bufnr('%')
  call finder.start(session)
  let ui_bufnr = bufnr('%')

  try
    call assert_notequal(original_bufnr, ui_bufnr)
    call assert_equal('A', s:consume_keys())
    call assert_equal('luis-pmenu', &l:filetype)
    call assert_equal(['Source: mock_source', '>'], getline(1, line('$')))
    call assert_equal(2, winnr('$'))
    call assert_equal(1, winnr())
    call assert_true(finder.is_active())

    let finder.last_candidates = [
    \   { 'word': 'foo', 'user_data': {} },
    \   { 'word': 'bar', 'user_data': {} },
    \   { 'word': 'baz', 'user_data': {} },
    \ ]
    let finder.last_pattern_raw = '>'

    call assert_equal(finder.last_candidates[0], finder.guess_candidate())

    call finder.quit()

    call assert_notequal('luis-pmenu', &l:filetype)
    call assert_equal(original_bufnr, bufnr('%'))
    call assert_equal(1, winnr('$'))
    call assert_equal(1, winnr())
    call assert_false(finder.is_active())
  finally
    execute ui_bufnr 'bwipeout!' 
  endtry
endfunction

function! s:test_guess_candidate__from_selected_candidate() abort
  let finder = luis#finder#pmenu#new({})
  let session = luis#session#new(
  \   finder,
  \   CreateMockSource(),
  \   CreateMockMatcher(),
  \   CreateMockComparer(),
  \   CreateMockPreviewer(),
  \   CreateMockHook()
  \ )

  call assert_false(finder.is_active())

  let original_bufnr = bufnr('%')
  call finder.start(session)
  let ui_bufnr = bufnr('%')

  try
    call assert_notequal(original_bufnr, ui_bufnr)
    call assert_equal('A', s:consume_keys())
    call assert_equal('luis-pmenu', &l:filetype)
    call assert_equal(['Source: mock_source', '>'], getline(1, line('$')))
    call assert_equal(2, winnr('$'))
    call assert_equal(1, winnr())
    call assert_true(finder.is_active())

    let finder.last_candidates = [
    \   { 'word': 'foo', 'user_data': {} },
    \   { 'word': 'bar', 'user_data': {} },
    \   { 'word': 'baz', 'user_data': {} },
    \ ]
    call setline(line('.'), 'bar')

    call assert_equal(finder.last_candidates[1], finder.guess_candidate())

    call finder.quit()

    call assert_notequal('luis-pmenu', &l:filetype)
    call assert_equal(original_bufnr, bufnr('%'))
    call assert_equal(1, winnr('$'))
    call assert_equal(1, winnr())
    call assert_false(finder.is_active())
  finally
    execute ui_bufnr 'bwipeout!' 
  endtry
endfunction

function! s:test_guess_candidate__from_default_candidate() abort
  let finder = luis#finder#pmenu#new({})
  let session = luis#session#new(
  \   finder,
  \   CreateMockSource(),
  \   CreateMockMatcher(),
  \   CreateMockComparer(),
  \   CreateMockPreviewer(),
  \   CreateMockHook()
  \ )

  call assert_false(finder.is_active())

  let original_bufnr = bufnr('%')
  call finder.start(session)
  let ui_bufnr = bufnr('%')

  try
    call assert_notequal(original_bufnr, ui_bufnr)
    call assert_equal('A', s:consume_keys())
    call assert_equal('luis-pmenu', &l:filetype)
    call assert_equal(['Source: mock_source', '>'], getline(1, line('$')))
    call assert_equal(2, winnr('$'))
    call assert_equal(1, winnr())
    call assert_true(finder.is_active())

    let finder.last_candidates = []
    let finder.last_pattern_raw = '>VIM'
    call setline(line('.'), '>VIM')

    call assert_equal({ 'word': 'VIM', 'user_data': {} }, finder.guess_candidate())

    call finder.quit()

    call assert_notequal('luis-pmenu', &l:filetype)
    call assert_equal(original_bufnr, bufnr('%'))
    call assert_equal(1, winnr('$'))
    call assert_equal(1, winnr())
    call assert_false(finder.is_active())
  finally
    execute ui_bufnr 'bwipeout!' 
  endtry
endfunction

function! s:test_refresh_candidates() abort
  let [finder, finder_spies] = SpyDict(luis#finder#pmenu#new({}))
  let session = luis#session#new(
  \   finder,
  \   CreateMockSource(),
  \   CreateMockMatcher(),
  \   CreateMockComparer(),
  \   CreateMockPreviewer(),
  \   CreateMockHook()
  \ )

  call assert_false(finder.is_active())

  let original_bufnr = bufnr('%')
  call finder.start(session)
  let ui_bufnr = bufnr('%')

  try
    call assert_notequal(original_bufnr, ui_bufnr)
    call assert_equal('A', s:consume_keys())
    call assert_equal('luis-pmenu', &l:filetype)
    call assert_equal(['Source: mock_source', '>'], getline(1, line('$')))
    call assert_equal(2, winnr('$'))
    call assert_equal(1, winnr())
    call assert_true(finder.is_active())

    function! s:on_CompleteDone() abort closure
      call finder.refresh_candidates()
      call assert_equal("\<C-x>", nr2char(getchar(0)))
      call assert_equal("\<C-o>", nr2char(getchar(0)))
    endfunction

    autocmd! CompleteDone <buffer>  call s:on_CompleteDone()

    normal! A

    call assert_equal(1, finder_spies.refresh_candidates.call_count())

    call finder.quit()

    call assert_notequal('luis-pmenu', &l:filetype)
    call assert_equal(original_bufnr, bufnr('%'))
    call assert_equal(1, winnr('$'))
    call assert_equal(1, winnr())
    call assert_false(finder.is_active())
  finally
    execute ui_bufnr 'bwipeout!' 
  endtry
endfunction

function! s:test_start__without_initial_pattern() abort
  let finder = luis#finder#pmenu#new({})
  let session = luis#session#new(
  \   finder,
  \   CreateMockSource(),
  \   CreateMockMatcher(),
  \   CreateMockComparer(),
  \   CreateMockPreviewer(),
  \   CreateMockHook()
  \ )

  call assert_false(finder.is_active())

  let original_bufnr = bufnr('%')
  call finder.start(session)
  let ui_bufnr = bufnr('%')

  try
    call assert_notequal(original_bufnr, ui_bufnr)
    call assert_equal('A', s:consume_keys())
    call assert_equal('luis-pmenu', &l:filetype)
    call assert_equal(['Source: mock_source', '>'], getline(1, line('$')))
    call assert_equal(2, winnr('$'))
    call assert_equal(1, winnr())
    call assert_true(finder.is_active())

    call finder.quit()

    call assert_notequal('luis-pmenu', &l:filetype)
    call assert_equal(original_bufnr, bufnr('%'))
    call assert_equal(1, winnr('$'))
    call assert_equal(1, winnr())
    call assert_false(finder.is_active())


    " Reuse the existing luis buffer.
    call finder.start(session)

    call assert_equal('A', s:consume_keys())
    call assert_equal(ui_bufnr, bufnr('%'))
    call assert_equal('luis-pmenu', &l:filetype)
    call assert_equal(['Source: mock_source', '>'], getline(1, line('$')))
    call assert_equal(2, winnr('$'))
    call assert_equal(1, winnr())
    call assert_true(finder.is_active())

    call finder.quit()

    call assert_notequal('luis-pmenu', &l:filetype)
    call assert_equal(original_bufnr, bufnr('%'))
    call assert_equal(1, winnr('$'))
    call assert_equal(1, winnr())
    call assert_false(finder.is_active())

    " Start after unload the existing luis buffer.
    call finder.start(session)

    call assert_equal('A', s:consume_keys())
    call assert_equal(ui_bufnr, bufnr('%'))
    call assert_equal('luis-pmenu', &l:filetype)
    call assert_equal(['Source: mock_source', '>'], getline(1, line('$')))
    call assert_equal(2, winnr('$'))
    call assert_equal(1, winnr())
    call assert_true(finder.is_active())

    call finder.quit()

    call assert_notequal('luis-pmenu', &l:filetype)
    call assert_equal(original_bufnr, bufnr('%'))
    call assert_equal(1, winnr('$'))
    call assert_equal(1, winnr())
    call assert_false(finder.is_active())
  finally
    execute ui_bufnr 'bwipeout!' 
  endtry
endfunction

function! s:test_start__with_initial_pattern() abort
  let finder = luis#finder#pmenu#new({
  \   'initial_pattern': 'VIM',
  \ })
  let session = luis#session#new(
  \   finder,
  \   CreateMockSource(),
  \   CreateMockMatcher(),
  \   CreateMockComparer(),
  \   CreateMockPreviewer(),
  \   CreateMockHook()
  \ )

  call assert_false(finder.is_active())

  let original_bufnr = bufnr('%')
  call finder.start(session)
  let ui_bufnr = bufnr('%')

  try
    call assert_notequal(original_bufnr, ui_bufnr)
    call assert_equal('A', s:consume_keys())
    call assert_equal('luis-pmenu', &l:filetype)
    call assert_equal(['Source: mock_source', '>VIM'], getline(1, line('$')))
    call assert_equal(2, winnr('$'))
    call assert_equal(1, winnr())
    call assert_true(finder.is_active())

    call finder.quit()

    call assert_notequal('luis-pmenu', &l:filetype)
    call assert_equal(original_bufnr, bufnr('%'))
    call assert_equal(1, winnr('$'))
    call assert_equal(1, winnr())
    call assert_false(finder.is_active())

    call finder.start(session)

    " Reuse existing luis buffer.
    call assert_equal(ui_bufnr, bufnr('%'))
    call assert_equal('A', s:consume_keys())
    call assert_equal('luis-pmenu', &l:filetype)
    call assert_equal(['Source: mock_source', '>VIM'], getline(1, line('$')))
    call assert_equal(2, winnr('$'))
    call assert_equal(1, winnr())
    call assert_true(finder.is_active())

    call finder.quit()

    call assert_notequal('luis-pmenu', &l:filetype)
    call assert_equal(original_bufnr, bufnr('%'))
    call assert_equal(1, winnr('$'))
    call assert_equal(1, winnr())
    call assert_false(finder.is_active())
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
