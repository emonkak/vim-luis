function! s:test_gather_candidates() abort
  " Clear registers except read-only registers.
  0verbose let original_registers = s:clear_registers()

  " " Clear "." register.
  " normal! i
  "
  " " Add "a", "b", "c", registers.
  " call setreg('a', ['foo'], 'v')
  " call setreg('b', ['bar'], 'V')
  " call setreg('c', ['baz'], "\<C-v>")

  try
    " let source = luis#source#register#new()
    "
    " call source.on_source_enter()
    "
    " let candidates = source.gather_candidates({})
    " call assert_equal([
    " \   {
    " \     'word': '"a',
    " \     'menu': 'foo',
    " \     'user_data': { 'register_name': 'a' },
    " \     'kind': 'c',
    " \     'luis_sort_priority': 97,
    " \   },
    " \   {
    " \     'word': '"b',
    " \     'menu': 'bar',
    " \     'user_data': { 'register_name': 'b' },
    " \     'kind': 'l',
    " \     'luis_sort_priority': 98,
    " \   },
    " \   {
    " \     'word': '"c',
    " \     'menu': 'baz',
    " \     'user_data': { 'register_name': 'c' },
    " \     'kind': 'b',
    " \     'luis_sort_priority': 99,
    " \   },
    " \ ], candidates)
  finally
    call s:restore_registers(original_registers)
    bwipeout!
  endtry
endfunction

function! s:test_source_definition() abort
  let source = luis#source#register#new()
  let errors = luis#internal#validate_source(source)
  call assert_equal([], errors)
  call assert_equal('register', source.name)
endfunction

function! s:clear_registers() abort
  let REGISTER_CHARS = '"0123456789-abcdefghijklmnopqrstuvwxyz#=*+/'
  let registers = []
  for i in range(len(REGISTER_CHARS))
    let name = REGISTER_CHARS[i]
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
