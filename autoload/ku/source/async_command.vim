" ku source: async_command
" Module  "{{{1

let s:SOURCE_TEMPLATE = {
\   'gather_candidates': function('ku#source#async_command#gather_candidates'),
\   'kind': g:ku#kind#file#module,
\   'name': 'async_command',
\   'on_action': function('ku#source#default#on_action'),
\   'on_source_enter': function('ku#source#async_command#on_source_enter'),
\   'on_source_leave': function('ku#source#default#on_source_leave'),
\   'special_char_p': function('ku#source#default#special_char_p'),
\   'valid_for_acc_p': function('ku#source#default#valid_for_acc_p'),
\ }

function! ku#source#async_command#new(command, SelectorFn) abort
  let name = type(a:command) == v:t_list
  \        ? command[0]
  \        : matchstr(a:command, '^\S*')
  return extend({
  \   'name': 'async_command/' . name,
  \   '_command': a:command,
  \   '_selector_fn': a:SelectorFn,
  \   '_cached_candidates': [],
  \   '_job_id': 0,
  \   '_last_line': 0,
  \ }, s:SOURCE_TEMPLATE, 'keep')
endfunction








" Interface  "{{{1
function! ku#source#async_command#on_source_enter() abort dict "{{{2
  let self._job_id = jobstart(self._command, {
  \   'on_stdout': function('s:on_stdout', [], self),
  \   'on_exit': function('s:on_exit', [], self),
  \ })
  let self._last_line = ''
  let self._cached_candidates = []
endfunction




function! ku#source#async_command#on_source_leave() abort dict "{{{2
  if self._job_id != 0
    call jobclose(self._job_id)
  endif
endfunction




function! ku#source#async_command#gather_candidates(pattern) abort dict  "{{{2
  return self._cached_candidates
endfunction








" Misc.  "{{{1
function! s:on_stdout(job_id, data, event) abort dict  "{{{2
  let start = reltime()

  let has_changed = 0

  let line = self._last_line . a:data[0]
  if line != ''
    let candidate = self._selector_fn(line)
    if candidate isnot 0
      call add(self._cached_candidates, candidate)
      let has_changed = 1
    endif
  endif

  for line in a:data[1:-2]
    let candidate = self._selector_fn(line)
    if candidate isnot 0
      call add(self._cached_candidates, candidate)
      let has_changed = 1
    endif
  endfor

  let self._last_line = a:data[-1]

  if has_changed
    call ku#refresh_candidates()
  endif
endfunction








function! s:on_exit(job_id, exit_code, event) abort dict  "{{{2
  if self._job_id == a:job_id
    let self._job_id = 0
  endif
endfunction








" __END__  "{{{1
" vim: foldmethod=marker
