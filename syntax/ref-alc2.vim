" ============================================================================
" Language:     ref-alc2
" File:         syntax/ref-alc2.vim
" Author:       mojako <moja.ojj@gmail.com>
" URL:          https://github.com/mojako/ref-sources.vim
" Last Change:  2011-09-16
" ============================================================================

" s:cpo_save {{{1
let s:cpo_save = &cpo
set cpo&vim
"}}}

if exists('b:current_syntax')
    finish
endif

syn region  refAlcMidashi oneline concealends
  \ matchgroup=refAlcConceal start='^\*' end='\*'

syn match   refAlcLabel     '【.\{-}】'
syn match   refAlcURL       'https\?://\S\+'

syn match   refAlcKana      '｛.\{-}｝'

" Highlight Group Link
hi def link refAlcMidashi   Title
hi def link refAlcLabel     Constant
hi def link refAlcURL       Underlined
hi def link refAlcKana      Comment

let b:current_syntax = 'ref-alc2'

" s:cpo_save {{{1
let &cpo = s:cpo_save
unlet s:cpo_save
"}}}

" vim: set et sts=4 sw=4 wrap:
