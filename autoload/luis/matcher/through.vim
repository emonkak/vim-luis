function! luis#matcher#through#import() abort
  return s:Matcher
endfunction

let s:Matcher = {}

function! s:Matcher.filter_candidates(candidates, context) abort dict
  return a:candidates
endfunction

function! s:Matcher.format_candidate(candidate, index, context) abort dict
  return a:candidate
endfunction

function! s:Matcher.sort_candidates(candidates, context) abort dict
  return a:candidates
endfunction
