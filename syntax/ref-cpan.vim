" ============================================================================
" Language:     ref-cpan
" File:         syntax/ref-cpan.vim
" Author:       mojako <moja.ojj@gmail.com>
" URL:          https://github.com/mojako/ref-sources.vim
" Last Change:  2011-09-12
" ============================================================================

" s:cpo_save {{{1
let s:cpo_save = &cpo
set cpo&vim
"}}}

if exists('b:current_syntax')
    finish
endif

syn match   refCpanTitle    '^#.*$'

syn region  refCpanList matchgroup=refCpanListHead start='^  \* ' end='\n\n'
  \ contains=refCpanItalic,refCpanBold,refCpanCode

syn region  refCpanItalic oneline concealends
  \ matchgroup=refCpanConceal start='\*' end='\*'
syn region  refCpanBold oneline concealends
  \ matchgroup=refCpanConceal start='\*\*' end='\*\*'
syn region  refCpanCode oneline concealends
  \ matchgroup=refCpanConceal start='`' end='`'

syn include @refPerl syntax/perl.vim
unlet b:current_syntax

syn region  refCpanSampleCode start='^[\t ]\+\%([\t* ]\)\@!' end='^$'
  \ contains=@refPerl

" Highlight Group Link
hi def link refCpanTitle    Title
hi def link refCpanBold     Type
hi def link refCpanItalic   Constant
hi def link refCpanCode     Statement
hi def link refCpanListHead Identifier
hi def link refCpanList     Normal

let b:current_syntax = 'ref-cpan'

" s:cpo_save {{{1
let &cpo = s:cpo_save
unlet s:cpo_save
"}}}

" vim: set et sts=4 sw=4 wrap:
