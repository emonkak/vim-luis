let s:TYPE_LIST = 'list'
let s:TYPE_DICTIONARY = 'dictionary'
let s:TYPE_STRUCT = 'struct'
let s:TYPE_UNION = 'union'

let s:PRIMITIVE_TYPE_NAMES = {
\   v:t_bool: 'boolean',
\   v:t_dict: 'dictionary',
\   v:t_float: 'float',
\   v:t_func: 'function',
\   v:t_list: 'list',
\   v:t_number: 'number',
\   v:t_string: 'string',
\ }

function! ku#schema#validate(data, schema) abort
  let errors = []
  call s:validate(a:data, a:schema, '.', errors)
  return errors
endfunction

function! ku#schema#to_string(schema)  abort
  let optional_marker = get(a:schema, 'optional', 0) ? '?' : ''
  if type(a:schema.type) is v:t_number
    return get(s:PRIMITIVE_TYPE_NAMES, a:schema.type, 'unknown')
    \      . optional_marker
  elseif a:schema.type ==# s:TYPE_LIST
    return 'list<' . ku#schema#to_string(a:schema.item) . '>'
    \      . optional_marker
  elseif a:schema.type ==# s:TYPE_DICTIONARY
    return 'dictionary<' . ku#schema#to_string(a:schema.item) . '>'
    \      . optional_marker
  elseif a:schema.type ==# s:TYPE_STRUCT
    let props = []
    for [key, value] in items(a:schema.properties)
      call add(props, string(key) . ': ' . ku#schema#to_string(value))
    endfor
    return '{' . join(props, ', ') . '}' . optional_marker
  elseif a:schema.type ==# s:TYPE_UNION
    return 'union<'
    \      . join(map(a:schema.variants, 'ku#schema#to_string(v:val)'),
    \             ', ')
    \      . '>'
    \      . optional_marker
  else
    return 'unknown'
  endif
endfunction

function! s:validate(data, schema, path, errors) abort
  if type(a:schema.type) is v:t_number
    if type(a:data) isnot a:schema.type
      let error = printf('Key %s must be %s but given data is %s',
      \           string(a:path),
      \           string(ku#schema#to_string(a:schema)),
      \           string(a:data))
      call add(a:errors, error)
      return 0
    endif
    return 1
  elseif a:schema.type ==# s:TYPE_LIST
    let list_schema = {'type': v:t_list}
    if !s:validate(a:data, list_schema, a:path, a:errors)
      return 0
    endif
    let success = 1
    for i in range(len(a:data))
      let path = a:path . '[' . i . ']'
      if !s:validate(a:data[i], a:schema.item, path, a:errors)
        let success = 0
      endif
    endfor
    return success
  elseif a:schema.type ==# s:TYPE_DICTIONARY
    let dict_schema = {'type': v:t_dict}
    if !s:validate(a:data, dict_schema, a:path, a:errors)
      return 0
    endif
    let success = 1
    for [key, Value] in items(a:data)
      let path = a:path . (a:path[-1:] != '.' ? '.' : '') . key
      if !s:validate(Value, a:schema.item, path, a:errors)
        let success = 0
      endif
    endfor
    return success
  elseif a:schema.type ==# s:TYPE_STRUCT
    let dict_schema = {'type': v:t_dict}
    if !s:validate(a:data, dict_schema, a:path, a:errors)
      return 0
    endif
    let success = 1
    for [key, value] in items(a:schema.properties)
      let path = a:path . (a:path[-1:] != '.' ? '.' : '') . key
      let is_optional = get(value, 'optional', 0)
      if has_key(a:data, key)
        if !s:validate(a:data[key], value, path, a:errors)
          let success = 0
        endif
      elseif !is_optional
        let error = 'Key ' . string(path) . ' must be defined'
        call add(a:errors, error)
        let success = 0
      endif
    endfor
    return success
  elseif a:schema.type ==# s:TYPE_UNION
    for variant in a:schema.variants
      if s:validate(a:data, variant, a:path, [])
        return 1
      endif
    endfor
    let error = printf('Key %s must be either %s but given value is %s',
    \           string(a:path),
    \           join(map(a:schema.variants,
    \                    'string(ku#schema#to_string(v:val))'), ', '),
    \           string(a:data))
    call add(a:errors, error)
    return 0
  else
    throw printf('Unexpected type "%s". Allowed values are "%s", "%s", "%s", "%s" or v:t_ variables',
    \            a:schema.type,
    \            s:TYPE_LIST,
    \            s:TYPE_DICTIONARY,
    \            s:TYPE_STRUCT,
    \            s:TYPE_UNION)
  endif
endfunction
