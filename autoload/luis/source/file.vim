function luis#source#file#new(...)
  let directory = get(a:000, 0, 0)
  let source = copy(s:Source)
  let source._directory = directory
  let source._cached_candidates = {}
  return source
endfunction

let s:Source = {
\   'name': 'file',
\   'default_kind': g:luis#kind#file#export,
\   'matcher': g:luis#matcher#default,
\ }

function! s:Source.gather_candidates(pattern) abort dict
  let separator = s:path_separator()
  let [directory, show_hidden] = s:parse_pattern(a:pattern, separator)

  if !has_key(self._cached_candidates, directory)
    let candidates = []
    let expanded_directory = s:expand_path(directory)
    let path_prefix = directory == './' ? '' : directory

    for filename in s:readdir(expanded_directory)
      let relative_path = path_prefix . filename
      let absolute_path = fnamemodify(expanded_directory . filename, ':p')
      let type = getftype(absolute_path)
      let is_directory = type == 'dir'
      \                  || (type == 'link' && isdirectory(absolute_path))
      call add(candidates, {
      \   'word': relative_path,
      \   'abbr': relative_path . (is_directory ? separator : ''),
      \   'menu': type,
      \   'user_data': {
      \     'file_path': absolute_path,
      \   },
      \   '_is_directory': is_directory,
      \   '_is_hidden': filename[:0] ==# '.',
      \ })
    endfor

    let self._cached_candidates[directory] = candidates
  endif

  if !show_hidden
    return filter(copy(self._cached_candidates[directory]),
    \             '!v:val._is_hidden')
  endif

  return self._cached_candidates[directory]
endfunction

function! s:Source.is_special_char(char) abort dict
  return a:char == s:path_separator()
endfunction

function! s:Source.is_valid_for_acc(candidate, sep) abort dict
  return a:candidate._is_directory && a:sep == s:path_separator()
endfunction

function! s:Source.on_action(candidate) abort dict
  if !has_key(a:candidate.user_data, 'file_path')
    let a:candidate.user_data.file_path =
    \   fnamemodify(s:expand_path(a:candidate.word), ':p')
  endif
  return a:candidate
endfunction

function! s:Source.on_source_enter() abort dict
  let self._cached_candidates = {}
  if self._directory isnot 0
    lcd `=self._directory`
  endif
endfunction

function! s:Source.on_source_leave() abort dict
  if self._directory isnot 0
    lcd -
  endif
endfunction

function! s:expand_path(path) abort
  let path = a:path
  let path = substitute(path, '^\~', '$HOME', '')
  let path = substitute(path, '\$\h\w*', '\=expand(submatch(0))', '')
  return path
endfunction

function! s:parse_pattern(pattern, sep) abort
  if strridx(a:pattern, a:sep) == 0  " root directory
    return ['/', 0]
  else
    let components = split(a:pattern, a:sep, 1)
    if len(components) == 1  " no path separator
      let directory = './'
    else  " more than one path separators
      let directory = join(components[:-2], a:sep)
      if directory[-1:] !=# a:sep
        let directory .= a:sep
      endif
    endif
    let show_hidden = components[-1][:0] ==# '.'
    return [directory, show_hidden]
  endif
endfunction

function! s:readdir(directory) abort
  if exists('*readdir')
    return readdir(a:directory)
  else
    let files = []
    call extend(files, globpath(a:directory, '.*', 1, 1))
    call extend(files, globpath(a:directory, '*', 1, 1))
    call map(files, 'fnamemodify(v:val, ":t")')
    return files
  endif
endfunction

function! s:path_separator() abort
  return exists('+shellslash') && !&shellslash ? '\' : '/'
endfunction
