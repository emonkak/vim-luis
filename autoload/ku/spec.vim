" ku: spec
" Constants  "{{{1

let s:CONSTRAINT_TYPE = 'type'
let s:CONSTRAINT_LIST = 'list'
let s:CONSTRAINT_DICTIONARY = 'dictionary'
let s:CONSTRAINT_STRUCT = 'struct'
let s:CONSTRAINT_UNION = 'union'

let s:ALL_CONSTRAINTS = [
\   s:CONSTRAINT_TYPE,
\   s:CONSTRAINT_LIST,
\   s:CONSTRAINT_DICTIONARY,
\   s:CONSTRAINT_STRUCT,
\   s:CONSTRAINT_UNION,
\ ]

let s:TYPE_NAMES = {
\   v:t_number: 'number',
\   v:t_string: 'string',
\   v:t_func: 'function',
\   v:t_list: 'list',
\   v:t_dict: 'dictionary',
\   v:t_float: 'float',
\   v:t_bool: 'boolean',
\ }








" Interface  "{{{1
function! ku#spec#validate(data, spec) abort  "{{{2
  let errors = []
  call s:validate(a:data, a:spec, '.', errors)
  return errors
endfunction








function! ku#spec#to_string(spec)  abort "{{{2
  let optional_marker = get(a:spec, 'optional', 0) ? '?' : ''
  if a:spec.constraint ==# s:CONSTRAINT_TYPE
    return get(s:TYPE_NAMES, a:spec.body, 'unknown') . optional_marker
  elseif a:spec.constraint ==# s:CONSTRAINT_LIST
    return 'list<' . ku#spec#to_string(a:spec.body) . '>'
    \      . optional_marker
  elseif a:spec.constraint ==# s:CONSTRAINT_DICTIONARY
    return 'dictionary<' . ku#spec#to_string(a:spec.body) . '{}'
    \      . optional_marker
  elseif a:spec.constraint ==# s:CONSTRAINT_STRUCT
    let props = []
    for [key, value] in items(a:spec.body)
      call add(props, string(key) . ': ' . ku#spec#to_string(value))
    endfor
    return '{' . join(props, ', ') . '}' . optional_marker
  elseif a:spec.constraint ==# s:CONSTRAINT_UNION
    return 'union<'
    \      . join(map(a:spec.body, 'ku#spec#to_string(v:val)'),
    \             ', ')
    \      . '>'
    \      . optional_marker
  else
    return 'unknown'
  endif
endfunction








" Misc.  "{{{1
function! s:validate(data, spec, path, errors) abort  "{{{2
  if a:spec.constraint ==# s:CONSTRAINT_TYPE
    if type(a:data) != a:spec.body
      let error = printf('Key %s must be %s but given data is %s',
      \           string(a:path),
      \           string(ku#spec#to_string(a:spec)),
      \           string(a:data))
      call add(a:errors, error)
      return 0
    endif
    return 1
  elseif a:spec.constraint ==# s:CONSTRAINT_LIST
    let list_spec = {'constraint': s:CONSTRAINT_TYPE, 'body': v:t_list}
    if !s:validate(a:data, list_spec, a:path, a:errors)
      return 0
    endif
    let success = 1
    for i in range(len(a:data))
      let path = a:path . '[' . i . ']'
      if !s:validate(a:data[i], a:spec.body, path, a:errors)
        let success = 0
      endif
    endfor
    return success
  elseif a:spec.constraint ==# s:CONSTRAINT_DICTIONARY
    let dict_spec = {'constraint': s:CONSTRAINT_TYPE, 'body': v:t_dict}
    if !s:validate(a:data, dict_spec, a:path, a:errors)
      return 0
    endif
    let success = 1
    for [key, Value] in items(a:data)
      let path = trim(a:path, '.') . '.' . key
      if !s:validate(Value, a:spec.body, path, a:errors)
        let success = 0
      endif
    endfor
    return success
  elseif a:spec.constraint ==# s:CONSTRAINT_STRUCT
    let dict_spec = {'constraint': s:CONSTRAINT_TYPE, 'body': v:t_dict}
    if !s:validate(a:data, dict_spec, a:path, a:errors)
      return 0
    endif
    let success = 1
    for [key, value] in items(a:spec.body)
      let path = trim(a:path, '.', 2) . '.' . key
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
  elseif a:spec.constraint ==# s:CONSTRAINT_UNION
    for constraint in a:spec.body
      if s:validate(value, constraint, path, [])
        return 1
      endif
    endfor
    let error = printf('Key %s must be either %s but given value is %s',
    \           string(a:path),
    \           string(join(map(a:spec.body, 'ku#spec#to_string(v:val)'), ', ')),
    \           string(a:data))
    call add(a:errors, error)
    return 0
  else
    throw printf('Unexpected value %s for constraint. Allowed values are %s',
    \            string(a:spec.constraint),
    \            string(join(s:ALL_CONSTRAINTS, ', '))
    \ )
  endif
endfunction








" __END__  "{{{1
" vim: foldmethod=marker
