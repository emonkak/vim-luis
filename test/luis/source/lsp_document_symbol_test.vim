silent runtime! test/spy.vim
silent runtime! test/mock.vim

function! s:test_gather_candidates() abort
  if !has('nvim')
    return 'nvim is required.'
  endif

  " Note: The test for LSP requests is very challenging. So, I only check that
  " it is working without any errors.
  let source = luis#source#lsp_document_symbol#new(bufnr('%'))
  let refresh_candidates_spy = Spy({ -> 0 })
  let session = {
  \   'id': 1,
  \   'source': source,
  \   'ui': CreateMockUI(),
  \   'matcher': CreateMockMatcher(),
  \   'comparer': CreateMockComparer(),
  \   'previewer': CreateMockPreviewer(),
  \   'hook': CreateMockHook(),
  \   'initial_pattern': '',
  \ }
  let context = { 'session': session }

  call source.on_source_enter(context)

  call assert_equal([], source.gather_candidates(context))

  call source.on_source_leave(context)
endfunction

function! s:test_source_definition() abort
  if !has('nvim')
    return 'nvim is required.'
  endif

  let source = luis#source#lsp_document_symbol#new(bufnr('%'))
  call luis#_validate_source(source)
  call assert_equal('lsp/document_symbol', source.name)
endfunction
