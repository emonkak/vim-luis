let s:TYPE_DICT = 'dict'
let s:TYPE_LIST = 'list'
let s:TYPE_STRUCT = 'struct'
let s:TYPE_UNION = 'union'
let s:TYPE_VALUE = 'value'

let s:PRIMITIVE_TYPE_NAMES = {
\   v:t_bool: 'Boolean',
\   v:t_dict: 'Dictionary',
\   v:t_float: 'Float',
\   v:t_func: 'Funcref',
\   v:t_list: 'List',
\   v:t_number: 'Number',
\   v:t_string: 'String',
\ }

function! luis#schema#validate(schema, value) abort
  let errors = []
  call s:validate(a:schema, a:value, '.', errors)
  return errors
endfunction

function! luis#schema#to_string(schema) abort
  if type(a:schema.type) is v:t_number
    let s = get(s:PRIMITIVE_TYPE_NAMES, a:schema.type, 'unknown')
  elseif a:schema.type ==# s:TYPE_DICT
    let s = 'Dictionary<' . luis#schema#to_string(a:schema.item) . '>'
  elseif a:schema.type ==# s:TYPE_LIST
    let s = 'List<' . luis#schema#to_string(a:schema.item) . '>'
  elseif a:schema.type ==# s:TYPE_STRUCT
    let attributes = []
    for [key, schema] in items(a:schema.attributes)
      call add(attributes, string(key) . ': ' . luis#schema#to_string(schema))
    endfor
    let s = '{' . join(attributes, ', ') . '}'
  elseif a:schema.type ==# s:TYPE_UNION
    let s = 'Union<'
    \      . join(map(copy(a:schema.variants),
    \                 'luis#schema#to_string(v:val)'), ', ')
    \      . '>'
  elseif a:schema.type ==# s:TYPE_VALUE
    let s = string(a:schema.value)
  else
    let s = 'Unknown'
  endif
  if get(a:schema, 'optional', 0)
    let s .= '?'
  endif
  return s
endfunction

function! s:validate(schema, value, path, errors) abort
  if type(a:schema.type) is v:t_number
    if type(a:value) isnot a:schema.type
      let error = printf('Key %s must be type %s but given value is %s',
      \   string(a:path),
      \   string(luis#schema#to_string(a:schema)),
      \   string(a:value)
      \ )
      call add(a:errors, error)
      return 0
    endif
    return 1
  elseif a:schema.type ==# s:TYPE_DICT
    if !s:validate({ 'type': v:t_dict }, a:value, a:path, a:errors)
      return 0
    endif
    let success = 1
    for [K, V] in items(a:value)
      let path = a:path . (a:path[-1:] != '.' ? '.' : '') . K
      if !s:validate(a:schema.item, V, path, a:errors)
        let success = 0
      endif
    endfor
    return success
  elseif a:schema.type ==# s:TYPE_LIST
    if !s:validate({ 'type': v:t_list }, a:value, a:path, a:errors)
      return 0
    endif
    let success = 1
    for i in range(len(a:value))
      let path = a:path . '[' . i . ']'
      if !s:validate(a:schema.item, a:value[i], path, a:errors)
        let success = 0
      endif
    endfor
    return success
  elseif a:schema.type ==# s:TYPE_STRUCT
    if !s:validate({ 'type': v:t_dict }, a:value, a:path, a:errors)
      return 0
    endif
    let success = 1
    for [K, V] in items(a:schema.attributes)
      let path = a:path . (a:path[-1:] != '.' ? '.' : '') . K
      if has_key(a:value, K)
        if !s:validate(V, a:value[K], path, a:errors)
          let success = 0
        endif
      elseif !get(V, 'optional', 0)
        let error = 'Key ' . string(path) . ' must be defined'
        call add(a:errors, error)
        let success = 0
      endif
    endfor
    return success
  elseif a:schema.type ==# s:TYPE_UNION
    for variant in a:schema.variants
      if s:validate(variant, a:value, a:path, [])
        return 1
      endif
    endfor
    let error = printf('Key %s must be either %s but given value is %s',
    \   string(a:path),
    \   join(map(
    \     copy(a:schema.variants),
    \     'string(luis#schema#to_string(v:val))'
    \   ), ', '),
    \   string(a:value)
    \ )
    call add(a:errors, error)
    return 0
  elseif a:schema.type ==# s:TYPE_VALUE
    if a:value is a:schema.value
      return 1
    endif
    let error = printf('Key %s must be value %s but given value is %s',
    \   string(a:path),
    \   string(a:schema.value),
    \   string(a:value)
    \ )
    call add(a:errors, error)
    return 0
  else
    let types = map(
    \   [
    \     s:TYPE_DICT,
    \     s:TYPE_LIST,
    \     s:TYPE_STRUCT,
    \     s:TYPE_UNION,
    \     s:TYPE_VALUE,
    \   ],
    \   'string(v:val)'
    \ )
    throw printf(
    \   'Unexpected type "%s". Allowed values are %s or v:t_ variables',
    \   a:schema.type,
    \   join(types, ',')
    \ )
  endif
endfunction
