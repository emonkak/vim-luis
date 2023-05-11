function! s:test_syntax() abort
  syntax enable

  enew
  setfiletype luis
  call setline(1, ['Source: buffer', '>vim'])

  try
    let IL = 'luisInputLine'
    let IP = 'luisInputPrompt'
    let IX = 'luisInputPattern'
    let SL = 'luisStatusLine'
    let SN = 'luisSourceName'
    let SP = 'luisSourcePrompt'
    let SS = 'luisSourceSeparator'

    let _ = [
    \   [1, 1, [SL, SP]],
    \   [1, 6, [SL, SP]],
    \   [1, 7, [SL, SS]],
    \   [1, 8, [SL, SS]],
    \   [1, 9, [SL, SN]],
    \   [1, 14, [SL, SN]],
    \   [2, 1, [IL, IP]],
    \   [2, 2, [IL, IX]],
    \   [2, 4, [IL, IX]],
    \ ]
    for [lnum, col, stack] in _
      call assert_equal(stack, s:syn_stack(lnum, col))
    endfor

    " Highlightings for <Plug>(luis-choose-action)
    call assert_notequal(0, hlID('luisChooseAction'))
    call assert_notequal(0, hlID('luisChooseCandidate'))
    call assert_notequal(0, hlID('luisChooseKey'))
    call assert_notequal(0, hlID('luisChooseMessage'))
    call assert_notequal(0, hlID('luisChoosePrompt'))
    call assert_notequal(0, hlID('luisChooseKind'))
  finally
    silent bwipeout!
    syntax off
  endtry
endfunction

function! s:syn_stack(lnum, col) abort
  return map(synstack(a:lnum, a:col), 'synIDattr(v:val, "name")')
endfunction
