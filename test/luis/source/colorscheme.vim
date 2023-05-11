function s:test_gather_candidates() abort
  let source = luis#source#colorscheme#new()

  let original_runtimepath = &runtimepath
  let package_dir = getcwd() . '/test/data'
  let &runtimepath = package_dir

  try
    call source.on_source_enter()

    let candidates = source.gather_candidates({ 'pattern': 'VIM' })
    call assert_equal([
    \   {
    \     'word': 'A',
    \     'menu': package_dir,
    \   },
    \   {
    \     'word': 'B',
    \     'menu': package_dir,
    \   },
    \   {
    \     'word': 'C',
    \     'menu': package_dir,
    \   },
    \ ], candidates)
  finally
    let &runtimepath = original_runtimepath
  endtry
endfunction

function s:test_source_definition() abort
  let source = luis#source#colorscheme#new()
  let errors = luis#internal#validate_source(source)
  call assert_equal([], errors)
  call assert_equal('colorscheme', source.name)
endfunction
