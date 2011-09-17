" ============================================================================
" Language:     ref-jquery
" File:         syntax/ref-jquery.vim
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

syn match   refJqueryOptionName '^\[.\{-}\]'

syn region  refJqueryBold oneline concealends
  \ matchgroup=refJqueryConceal start='\*' end='\*'
syn region  refJqueryCode oneline concealends
  \ matchgroup=refJqueryConceal start='`' end='`'

if globpath(&rtp, 'syntax/jquery.vim') != ''
    syn include @refJavascript syntax/jquery.vim
else
    syn include @refJavascript syntax/javascript.vim
endif
unlet b:current_syntax

syn region  refJquerySampleCode start='^    ' end='^$'
  \ contains=@refJavascript,refJqueryConceal

syn include @refHtml syntax/html.vim
unlet b:current_syntax

syn region  refJquerySampleHtml start='\n    \s*<' end='^$'
  \ contains=@refHtml,refJqueryConceal

syn region  refJqueryKeyword oneline concealends
  \ matchgroup=refJqueryConceal start='^|' end='|$'

" Highlight Group Link
hi def link refJqueryOptionName Identifier
hi def link refJqueryBold       Type
hi def link refJqueryCode       Statement

let b:current_syntax = 'ref-jquery'

" s:cpo_save {{{1
let &cpo = s:cpo_save
unlet s:cpo_save
"}}}

" vim: set et sts=4 sw=4 wrap:
