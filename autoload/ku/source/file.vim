" ku source: file
" Module  "{{{1

let s:SOURCE_TEMPLATE = {
\   'name': 'file',
\   'default_kind': g:ku#kind#file#export,
\   'matcher': g:ku#matcher#default,
\   'gather_candidates': function('ku#source#file#gather_candidates'),
\   'on_action': function('ku#source#file#on_action'),
\   'on_source_enter': function('ku#source#file#on_source_enter'),
\   'on_source_leave': function('ku#source#file#on_source_leave'),
\   'special_char_p': function('ku#source#file#special_char_p'),
\   'valid_for_acc_p': function('ku#source#file#valid_for_acc_p'),
\ }

function! ku#source#file#new(search_directory = 0) abort
  return extend({
  \  '_cached_candidates': {},
  \  '_search_directory': a:search_directory,
  \  }, s:SOURCE_TEMPLATE, 'keep')
endfunction








" Interface  "{{{1
function! ku#source#file#gather_candidates(pattern) abort dict  "{{{2
  let separator = s:path_separator()
  let [directory, show_dotfiles_p] = s:parse_pattern(a:pattern, separator)

  if !has_key(self._cached_candidates, directory)
    let candidates = []
    let expanded_directory = expandcmd(directory)
    let prefix = directory == './' ? '' : directory
    for filename in readdir(expanded_directory)
      let path = prefix . filename
      let absolute_path = fnamemodify(expanded_directory . filename, ':p')
      let type = getftype(absolute_path)
      let directory_p = type == 'dir'
      \                 || (type == 'link' && isdirectory(absolute_path))
      call add(candidates, {
      \   'word': path,
      \   'abbr': path . (directory_p ? separator : ''),
      \   'menu': type,
      \   'user_data': {
      \     'ku_file_path': absolute_path,
      \   },
      \   'ku_dotfile_p': filename[:0] ==# '.',
      \   'ku_directory_p': directory_p,
      \ })
    endfor
    let self._cached_candidates[directory] = candidates
  endif

  if !show_dotfiles_p
    return filter(copy(self._cached_candidates[directory]),
    \             '!v:val.ku_dotfile_p')
  endif

  return self._cached_candidates[directory]
endfunction




function! ku#source#file#on_source_enter() abort dict  "{{{2
  let self._cached_candidates = {}
  if self._search_directory isnot 0
    lcd `=self._search_directory`
  endif
endfunction




function! ku#source#file#on_source_leave() abort dict  "{{{2
  if self._search_directory isnot 0
    lcd -
  endif
endfunction




function! ku#source#file#on_action(candidate) abort dict  "{{{2
  if !a:candidate.user_data.ku__completed_p
    let a:candidate.user_data.ku_file_path =
    \   fnamemodify(expandcmd(a:candidate.word), ':p')
  endif
  return a:candidate
endfunction




function! ku#source#file#special_char_p(char) abort dict  "{{{2
  return a:char == s:path_separator()
endfunction




function! ku#source#file#valid_for_acc_p(candidate, sep) abort dict  "{{{2
  return a:candidate.ku_directory_p && a:sep == s:path_separator()
endfunction








" Misc.  "{{{1
function! s:parse_pattern(pattern, separator) abort  "{{{2
  if strridx(a:pattern, a:separator) == 0  " root directory
    return ['/', 0]
  else
    let components = split(a:pattern, a:separator, 1)
    if len(components) == 1  " no path separator
      let directory = './'
    else  " more than one path separators
      let directory = trim(join(components[:-2], a:separator), a:separator, 2)
      \             . a:separator
    endif
    let show_dotfiles_p = components[-1][:0] ==# '.'
    return [directory, show_dotfiles_p]
  endif
endfunction




function! s:path_separator() abort  "{{{2
  return (exists('+shellslash') && !&shellslash) ? '\' : '/'
endfunction








" __END__  "{{{1
" vim: foldmethod=marker
