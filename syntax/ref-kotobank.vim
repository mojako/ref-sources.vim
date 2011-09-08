" ============================================================================
" Language:     ref-kotobank
" File:         syntax/ref-kotobank.vim
" Author:       mojako <moja.ojj@gmail.com>
" URL:          https://github.com/mojako/ref-sources.vim
" Last Change:  2011-09-09
" ============================================================================

scriptencoding utf-8

" s:cpo_save {{{1
let s:cpo_save = &cpo
set cpo&vim
"}}}

if exists('b:current_syntax')
    finish
endif

syn match   refKotobankDicName  '^.*の解説$'

syn region  refKotobankBold oneline concealends
  \ matchgroup=refKotobankConceal start='\*' end='\*'

syn match   refKotobankTitle    '\*.\{-}\*\n\ze　'
syn match   refKotobankTitle    '^ .\{-}\ze\%(\s*/.*/\)\?$'

syn region  refKotobankLabel oneline start='\[' end='\]'
syn region  refKotobankLabel oneline start='［' end='］'
syn region  refKotobankLabel oneline start='((' end='))'

syn match   refKotobankKana     '([ぁ-ん]\+)'

syn match   refKotobankExample  '^» .*$'

syn match   refKotobankURL      'https\?://\S\+'

" Highlight Group Link
hi def link refKotobankDicName  Type
hi def link refKotobankTitle    Title
hi def link refKotobankBold     Identifier
hi def link refKotobankLabel    Constant
hi def link refKotobankKana     Comment
hi def link refKotobankExample  Statement
hi def link refKotobankURL      Underlined

let b:current_syntax = 'ref-kotobank'

" s:cpo_save {{{1
let &cpo = s:cpo_save
unlet s:cpo_save
"}}}

" vim: set et sts=4 sw=4 wrap:
