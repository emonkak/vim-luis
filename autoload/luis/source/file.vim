function! luis#source#file#new() abort
  let source = copy(s:Source)
  let source.cached_candidates = {}
  return source
endfunction

let s:Source = {
\   'name': 'file',
\   'default_kind': luis#kind#file#import(),
\ }

function! s:Source.gather_candidates(context) abort dict
  let separator = s:path_separator()
  let [dir, rest_pattern] = s:parse_pattern(a:context.pattern, separator)

  if !has_key(self.cached_candidates, dir)
    let normal_candidates = []
    let hidden_candidates = []
    let logical_dir = dir == './' ? '' : dir
    let physical_dir = s:expand_path(dir)

    for filename in s:readdir(physical_dir)
      let logical_path = logical_dir . filename
      let physical_path = fnamemodify(physical_dir . filename, ':p')
      let user_data = { 'file_path': physical_path }
      let type = getftype(resolve(physical_path))
      if type ==# 'file'
        let user_data.preview_path = physical_path
      endif
      let is_hidden = filename[0] == '.'
      let target_candidates = is_hidden ? hidden_candidates : normal_candidates
      call add(target_candidates, {
      \   'word': logical_path,
      \   'abbr': logical_path . (type ==# 'dir' ? separator : ''),
      \   'kind': type,
      \   'user_data': user_data,
      \ })
    endfor

    let self.cached_candidates[dir] = [
    \    normal_candidates,
    \    hidden_candidates
    \ ]
  endif

  let [normal_candidates, hidden_candidates] = self.cached_candidates[dir]
  let candidates = []

  if rest_pattern[0] == '.'
    call extend(candidates, hidden_candidates)
  endif

  call extend(candidates, normal_candidates)

  if rest_pattern != '' && rest_pattern != '.'
    call add(candidates, {
    \   'word': a:context.pattern,
    \   'kind': '*new*',
    \   'user_data': {},
    \   'luis_sort_priority': 1,
    \ })
  endif

  return candidates
endfunction

function! s:Source.is_special_char(char) abort dict
  return a:char == s:path_separator()
endfunction

function! s:Source.is_valid_for_acc(candidate) abort dict
  return a:candidate.kind ==# 'dir'
endfunction

function! s:Source.on_action(candidate, context) abort dict
  if !has_key(a:candidate.user_data, 'file_path')
    let a:candidate.user_data.file_path =
    \   fnamemodify(s:expand_path(a:candidate.word), ':p')
  endif
endfunction

function! s:Source.on_source_enter(context) abort dict
  let self.cached_candidates = {}
endfunction

function! s:expand_path(path) abort
  let path = a:path
  let path = substitute(path, '\~/', '$HOME/', 'g')
  let path = substitute(path, '\$\h\w*', '\=expand(submatch(0))', 'g')
  return path
endfunction

function! s:parse_pattern(pattern, sep) abort
  if strridx(a:pattern, a:sep) == 0  " root directory
    return ['/', '']
  else
    let components = split(a:pattern, a:sep, 1)
    if len(components) == 1  " no path separator
      let dir = './'
    else  " more than one path separators
      let dir = join(components[:-2], a:sep)
      if dir[-1:] !=# a:sep
        let dir .= a:sep
      endif
    endif
    let filename = components[-1]
    return [dir, filename]
  endif
endfunction

function! s:path_separator() abort
  return exists('+shellslash') && !&shellslash ? '\' : '/'
endfunction

function! s:readdir(dir) abort
  if exists('*readdir')
    try
      return readdir(a:dir)
    catch /\<E484:/
      return []
    endtry
  else
    let paths = []
    call extend(paths, globpath(a:dir, '.*', 1, 1))
    call extend(paths, globpath(a:dir, '*', 1, 1))
    call map(paths, 'fnamemodify(v:val, ":t")')
    call filter(paths, 'v:val !~# "^\\.\\{1,2}$"')
    return paths
  endif
endfunction
