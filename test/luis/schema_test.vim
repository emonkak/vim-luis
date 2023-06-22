function! s:test_validate__type() abort
  let schema = { 'type': v:t_bool }
  call s:do_test_validate([], schema, v:false)
  call s:do_test_validate(["Key '.' must be type 'Boolean' but given value is 0"], schema, 0)
  call s:do_test_validate(["Key '.' must be type 'Boolean' but given value is 0.5"], schema, 0.5)
  call s:do_test_validate(["Key '.' must be type 'Boolean' but given value is 'vim'"], schema, 'vim')
  call s:do_test_validate(["Key '.' must be type 'Boolean' but given value is []"], schema, [])
  call s:do_test_validate(["Key '.' must be type 'Boolean' but given value is {}"], schema, {})
  call s:do_test_validate(["Key '.' must be type 'Boolean' but given value is function('function')"], schema, function('function'))

  let schema = { 'type': v:t_number }
  call s:do_test_validate(["Key '.' must be type 'Number' but given value is v:false"], schema, v:false)
  call s:do_test_validate([], schema, 0)
  call s:do_test_validate(["Key '.' must be type 'Number' but given value is 0.5"], schema, 0.5)
  call s:do_test_validate(["Key '.' must be type 'Number' but given value is 'vim'"], schema, 'vim')
  call s:do_test_validate(["Key '.' must be type 'Number' but given value is []"], schema, [])
  call s:do_test_validate(["Key '.' must be type 'Number' but given value is {}"], schema, {})
  call s:do_test_validate(["Key '.' must be type 'Number' but given value is function('function')"], schema, function('function'))

  let schema = { 'type': v:t_float }
  call s:do_test_validate(["Key '.' must be type 'Float' but given value is v:false"], schema, v:false)
  call s:do_test_validate(["Key '.' must be type 'Float' but given value is 0"], schema, 0)
  call s:do_test_validate([], schema, 0.5)
  call s:do_test_validate(["Key '.' must be type 'Float' but given value is 'vim'"], schema, 'vim')
  call s:do_test_validate(["Key '.' must be type 'Float' but given value is []"], schema, [])
  call s:do_test_validate(["Key '.' must be type 'Float' but given value is {}"], schema, {})
  call s:do_test_validate(["Key '.' must be type 'Float' but given value is function('function')"], schema, function('function'))

  let schema = { 'type': v:t_string }
  call s:do_test_validate(["Key '.' must be type 'String' but given value is v:false"], schema, v:false)
  call s:do_test_validate(["Key '.' must be type 'String' but given value is 0"], schema, 0)
  call s:do_test_validate(["Key '.' must be type 'String' but given value is 0.5"], schema, 0.5)
  call s:do_test_validate([], schema, 'vim')
  call s:do_test_validate(["Key '.' must be type 'String' but given value is []"], schema, [])
  call s:do_test_validate(["Key '.' must be type 'String' but given value is {}"], schema, {})
  call s:do_test_validate(["Key '.' must be type 'String' but given value is function('function')"], schema, function('function'))

  let schema = { 'type': v:t_list }
  call s:do_test_validate(["Key '.' must be type 'List' but given value is v:false"], schema, v:false)
  call s:do_test_validate(["Key '.' must be type 'List' but given value is 0"], schema, 0)
  call s:do_test_validate(["Key '.' must be type 'List' but given value is 0.5"], schema, 0.5)
  call s:do_test_validate(["Key '.' must be type 'List' but given value is 'vim'"], schema, 'vim')
  call s:do_test_validate([], schema, [])
  call s:do_test_validate(["Key '.' must be type 'List' but given value is {}"], schema, {})
  call s:do_test_validate(["Key '.' must be type 'List' but given value is function('function')"], schema, function('function'))

  let schema = { 'type': v:t_dict }
  call s:do_test_validate(["Key '.' must be type 'Dictionary' but given value is v:false"], schema, v:false)
  call s:do_test_validate(["Key '.' must be type 'Dictionary' but given value is 0"], schema, 0)
  call s:do_test_validate(["Key '.' must be type 'Dictionary' but given value is 0.5"], schema, 0.5)
  call s:do_test_validate(["Key '.' must be type 'Dictionary' but given value is 'vim'"], schema, 'vim')
  call s:do_test_validate(["Key '.' must be type 'Dictionary' but given value is []"], schema, [])
  call s:do_test_validate([], schema, {})
  call s:do_test_validate(["Key '.' must be type 'Dictionary' but given value is function('function')"], schema, function('function'))

  let schema = { 'type': v:t_func }
  call s:do_test_validate(["Key '.' must be type 'Funcref' but given value is v:false"], schema, v:false)
  call s:do_test_validate(["Key '.' must be type 'Funcref' but given value is 0"], schema, 0)
  call s:do_test_validate(["Key '.' must be type 'Funcref' but given value is 0.5"], schema, 0.5)
  call s:do_test_validate(["Key '.' must be type 'Funcref' but given value is 'vim'"], schema, 'vim')
  call s:do_test_validate(["Key '.' must be type 'Funcref' but given value is []"], schema, [])
  call s:do_test_validate(["Key '.' must be type 'Funcref' but given value is {}"], schema, {})
  call s:do_test_validate([], schema, function('function'))
endfunction

function! s:test_validate__dict() abort
  let schema = { 'type': 'dict', 'item': { 'type': v:t_string } }
  call s:do_test_validate([], schema, {})
  call s:do_test_validate([], schema, { 'foo': 'foo' })
  call s:do_test_validate([], schema, { 'foo': 'foo', 'bar': 'bar' })
  call s:do_test_validate(
  \   ["Key '.foo' must be type 'String' but given value is 123"],
  \   schema,
  \   { 'foo': 123 }
  \ )
  call s:do_test_validate(
  \   ["Key '.foo' must be type 'String' but given value is 123"],
  \   schema,
  \   { 'foo': 123, 'bar': 'bar' }
  \ )
  call s:do_test_validate(
  \   ["Key '.bar' must be type 'String' but given value is 456"],
  \   schema,
  \   { 'foo': 'foo', 'bar': 456 }
  \ )
  call s:do_test_validate(
  \   [
  \     "Key '.foo' must be type 'String' but given value is 123",
  \     "Key '.bar' must be type 'String' but given value is 456"
  \   ],
  \   schema,
  \   { 'foo': 123, 'bar': 456 }
  \ )
endfunction

function! s:test_validate__list() abort
  let schema = { 'type': 'list', 'item': { 'type': v:t_string } }
  call s:do_test_validate([], schema, [])
  call s:do_test_validate([], schema, ['foo'])
  call s:do_test_validate([], schema, ['foo', 'bar'])
  call s:do_test_validate(
  \   ["Key '.[0]' must be type 'String' but given value is 123"],
  \   schema,
  \   [123]
  \ )
  call s:do_test_validate(
  \   ["Key '.[0]' must be type 'String' but given value is 123"],
  \   schema,
  \   [123, 'foo']
  \ )
  call s:do_test_validate(
  \   ["Key '.[1]' must be type 'String' but given value is 456"],
  \   schema,
  \   ['foo', 456]
  \ )
  call s:do_test_validate(
  \   [
  \     "Key '.[0]' must be type 'String' but given value is 123",
  \     "Key '.[1]' must be type 'String' but given value is 456"
  \   ],
  \   schema,
  \   [123, 456]
  \ )
endfunction

function! s:test_validate__struct() abort
  let schema = {
  \   'type': 'struct',
  \   'attributes': {
  \     'foo': { 'type': v:t_number },
  \     'bar': { 'type': v:t_number, 'optional': 1 },
  \     'baz': { 'type': v:t_string },
  \   },
  \ }
  call s:do_test_validate([], schema, { 'foo': 123, 'bar': 456, 'baz': 'baz' })
  call s:do_test_validate([], schema, { 'foo': 123, 'baz': '789' })
  call s:do_test_validate(
  \   [
  \     "Key '.foo' must be defined",
  \     "Key '.baz' must be defined"
  \   ],
  \   schema,
  \   {}
  \ )
  call s:do_test_validate(
  \   [
  \     "Key '.foo' must be defined",
  \     "Key '.baz' must be defined"
  \   ],
  \   schema,
  \   { 'bar': 456 }
  \ )
  call s:do_test_validate(
  \   ["Key '.foo' must be defined"],
  \   schema,
  \   { 'baz': 'baz' }
  \ )
  call s:do_test_validate(
  \   ["Key '.foo' must be defined"],
  \   schema,
  \   { 'bar': 456, 'baz': 'baz' }
  \ )
  call s:do_test_validate(
  \   ["Key '.baz' must be defined"],
  \   schema,
  \   { 'foo': 123 }
  \ )
  call s:do_test_validate(
  \   ["Key '.baz' must be defined"],
  \   schema,
  \   { 'foo': 123, 'bar': 456 }
  \ )
  call s:do_test_validate(
  \   ["Key '.foo' must be type 'Number' but given value is 'foo'"],
  \   schema,
  \   { 'foo': 'foo', 'bar': 456, 'baz': 'baz' }
  \ )
  call s:do_test_validate(
  \   ["Key '.bar' must be type 'Number?' but given value is 'bar'"],
  \   schema,
  \   { 'foo': 123, 'bar': 'bar', 'baz': 'baz' }
  \ )
  call s:do_test_validate(
  \   ["Key '.baz' must be type 'String' but given value is 789"],
  \   schema,
  \   { 'foo': 123, 'bar': 456, 'baz': 789 }
  \ )
endfunction

function! s:test_validate__union() abort
  let schema = {
  \   'type': 'union',
  \   'variants': [{ 'type': v:t_string }, { 'type': v:t_number }]
  \ }
  call s:do_test_validate([
  \   "Key '.' must be either 'String', 'Number' but given value is v:false"],
  \   schema,
  \   v:false
  \ )
  call s:do_test_validate([], schema, 0)
  call s:do_test_validate(
  \   ["Key '.' must be either 'String', 'Number' but given value is 0.5"],
  \   schema,
  \   0.5
  \ )
  call s:do_test_validate([], schema, 'vim')
  call s:do_test_validate([
  \   "Key '.' must be either 'String', 'Number' but given value is []"],
  \   schema,
  \   []
  \ )
  call s:do_test_validate([
  \   "Key '.' must be either 'String', 'Number' but given value is {}"],
  \   schema,
  \   {}
  \ )
  call s:do_test_validate([
  \   "Key '.' must be either 'String', 'Number' but given value is function('function')"],
  \   schema,
  \   function('function')
  \ )
endfunction

function! s:test_validate__value() abort
  let schema = { 'type': 'value', 'value': 1 }
  call s:do_test_validate(
  \   ["Key '.' must be value 1 but given value is 0"],
  \   schema,
  \   0
  \ )
  call s:do_test_validate([], schema, 1)
  call s:do_test_validate(
  \   ["Key '.' must be value 1 but given value is 0.0"],
  \   schema,
  \   0.0
  \ )
  call s:do_test_validate(
  \   ["Key '.' must be value 1 but given value is 1.0"],
  \   schema,
  \   1.0
  \ )
  call s:do_test_validate(
  \   ["Key '.' must be value 1 but given value is '0'"],
  \   schema,
  \   '0'
  \ )
  call s:do_test_validate(
  \   ["Key '.' must be value 1 but given value is '1'"],
  \   schema,
  \   '1'
  \ )
  call s:do_test_validate(
  \   ["Key '.' must be value 1 but given value is v:false"],
  \   schema,
  \   v:false
  \ )
  call s:do_test_validate(
  \   ["Key '.' must be value 1 but given value is v:true"],
  \   schema,
  \   v:true
  \ )
endfunction

function! s:test_to_string() abort
  let schema = { 'type': v:t_bool }
  call s:do_test_to_string('Boolean', schema)

  let schema = { 'type': v:t_number }
  call s:do_test_to_string('Number', schema)

  let schema = { 'type': v:t_float }
  call s:do_test_to_string('Float', schema)

  let schema = { 'type': v:t_string }
  call s:do_test_to_string('String', schema)

  let schema = { 'type': v:t_list }
  call s:do_test_to_string('List', schema)

  let schema = { 'type': v:t_dict }
  call s:do_test_to_string('Dictionary', schema)

  let schema = { 'type': v:t_func }
  call s:do_test_to_string('Funcref', schema)

  let schema = { 'type': 'dict', 'item': { 'type': v:t_string } }
  call s:do_test_to_string('Dictionary<String>', schema)

  let schema = { 'type': 'list', 'item': { 'type': v:t_string } }
  call s:do_test_to_string('List<String>', schema)

  let schema = {
  \   'type': 'struct',
  \   'attributes': {
  \     'foo': { 'type': v:t_number },
  \     'bar': { 'type': v:t_string, 'optional': 1 },
  \   },
  \ }
  if keys(schema.attributes)[0] ==# 'foo'
    call s:do_test_to_string("{'foo': Number, 'bar': String?}", schema)
  else
    call s:do_test_to_string("{'bar': String?, 'foo': Number}", schema)
  endif

  let schema = {
  \   'type': 'union',
  \   'variants': [{ 'type': v:t_string }, { 'type': v:t_number }]
  \ }
  call s:do_test_to_string('Union<String, Number>', schema)

  let schema = { 'type': 'value', 'value': 1 }
  call s:do_test_to_string('1', schema)
endfunction

function! s:do_test_validate(expected_errors, schema, value) abort
  call assert_equal(a:expected_errors, luis#schema#validate(a:schema, a:value))
endfunction

function! s:do_test_to_string(expected_string, schema) abort
  call assert_equal(a:expected_string, luis#schema#to_string(a:schema))
endfunction
