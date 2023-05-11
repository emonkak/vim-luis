if exists('g:loaded_spy')
  finish
endif

function! Spy(func_ref) abort
  let spy = copy(s:Spy)
  let spy._func_ref = a:func_ref
  let spy._calls = []
  return spy
endfunction

let s:Spy = {}

function! s:Spy.call(args, ...) abort dict
  if a:0 > 0
    let return_value = call(self._func_ref, a:args, a:1)
    call add(self._calls, {
    \   'args': a:args,
    \   'return_value': return_value,
    \   'self': a:1,
    \ })
  else
    let return_value = call(self._func_ref, a:args)
    call add(self._calls, {
    \   'args': a:args,
    \   'return_value': return_value,
    \ })
  endif
  return return_value
endfunction

function! s:Spy.call_count() abort dict
  return len(self._calls)
endfunction

function! s:Spy.calls() abort dict
  return self._calls
endfunction

function! s:Spy.called() abort dict
  return len(self._calls) > 0
endfunction

function! s:Spy.to_funcref() abort dict
  let spy = self
  let wrapper = {}

  function! wrapper.call(...) abort closure
    if self is wrapper
      return spy.call(a:000)
    else
      return spy.call(a:000, self)
    endif
  endfunction

  return wrapper.call
endfunction

function! s:test_call() abort
  let spy = Spy({ name -> 'Hello ' . name . '!' })
  call assert_equal('Hello Vim!', spy.call(['Vim']))
  call assert_equal(1, spy.call_count())
  call assert_equal([{ 'args': ['Vim'], 'return_value': 'Hello Vim!' }], spy.calls())

  let F = spy.to_funcref()
  call assert_equal('Hello NeoVim!', F('NeoVim'))
  call assert_equal(2, spy.call_count())
  call assert_equal([
  \   { 'args': ['Vim'], 'return_value': 'Hello Vim!' },
  \   { 'args': ['NeoVim'], 'return_value': 'Hello NeoVim!' },
  \ ], spy.calls())
endfunction

function! s:test_call__with_dict() abort
  let _ = {}

  function! _.call() abort dict
    return 'Hello ' . self.name . '!'
  endfunction

  let spy = Spy(_.call)
  call assert_equal('Hello Vim!', spy.call([], { 'name': 'Vim' }))
  call assert_equal(1, spy.call_count())
  call assert_equal([
  \   { 'args': [], 'return_value': 'Hello Vim!', 'self': { 'name': 'Vim' } },
  \ ], spy.calls())

  let F = spy.to_funcref()
  call assert_equal('Hello NeoVim!', call(F, [], { 'name': 'NeoVim' }))
  call assert_equal(2, spy.call_count())
  call assert_equal([
  \   { 'args': [], 'return_value': 'Hello Vim!', 'self': { 'name': 'Vim' } },
  \   { 'args': [], 'return_value': 'Hello NeoVim!', 'self': { 'name': 'NeoVim' } },
  \ ], spy.calls())
endfunction

let g:loaded_spy = 1
