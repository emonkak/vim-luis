let s:ALL_REGISTER_CHARS = '"0123456789-abcdefghijklmnopqrstuvwxyz#=*+/'

function! s:test_gather_candidates() abort
  0verbose let saved_registers = s:clean_registers(s:ALL_REGISTER_CHARS)

  " Clear the content of "." register.
  normal! i

  call setreg('a', ['foo'], 'v')
  call setreg('b', ['bar', 'foo'], 'V')
  call setreg('c', ['baz', 'bar', 'foo'], "\<C-v>")

  try
    let source = luis#source#register#new()

    call source.on_source_enter({})

    let candidates = source.gather_candidates({})
    call assert_equal([
    \   {
    \     'word': 'foo',
    \     'menu': '"a',
    \     'user_data': {
    \       'register_name': 'a',
    \       'preview_lines': ['foo'],
    \     },
    \     'kind': 'c',
    \     'dup': 1,
    \     'luis_sort_priority': -char2nr('a'),
    \   },
    \   {
    \     'word': 'bar',
    \     'menu': '"b',
    \     'user_data': {
    \       'register_name': 'b',
    \       'preview_lines': ['bar', 'foo'],
    \     },
    \     'kind': 'l',
    \     'dup': 1,
    \     'luis_sort_priority': -char2nr('b'),
    \   },
    \   {
    \     'word': 'baz',
    \     'menu': '"c',
    \     'user_data': {
    \       'register_name': 'c',
    \       'preview_lines': ['baz', 'bar', 'foo'],
    \     },
    \     'kind': 'b',
    \     'dup': 1,
    \     'luis_sort_priority': -char2nr('c'),
    \   },
    \ ], candidates)
  finally
    call s:restore_registers(saved_registers)
    bwipeout!
  endtry
endfunction

function! s:test_source_definition() abort
  let source = luis#source#register#new()
  call assert_true(luis#validate_source(source))
  call assert_equal('register', source.name)
endfunction

function! s:clean_registers(register_chars) abort
  " Clean register contents except read-only registers.
  let registers = []
  for i in range(len(a:register_chars))
    let name = a:register_chars[i]
    let value = getreg(name, 1)
    if value == ''
      continue
    endif
    let type = getregtype(name)
    call add(registers, [name, value, type])
    call setreg(name, [])
  endfor
  return registers
endfunction

function! s:restore_registers(registers) abort
  for [name, value, type] in a:registers
    call setreg(name, value, type)
  endfor
endfunction
