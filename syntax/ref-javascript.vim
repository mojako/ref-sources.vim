" ============================================================================
" Language:     ref-javascript
" File:         syntax/ref-jquery.vim
" Author:       mojako <moja.ojj@gmail.com>
"               shiwano <shiwano@gmail.com>
" URL:          https://github.com/mojako/ref-sources.vim
" Last Change:  2012-03-16
" ============================================================================

" s:cpo_save {{{1
let s:cpo_save = &cpo
set cpo&vim
"}}}

if exists('b:current_syntax')
    finish
endif

syn region  refJavascriptCode oneline concealends
  \ matchgroup=refJavascriptConceal start='`' end='`'
syn region  refJavascriptVar oneline concealends
  \ matchgroup=refJavascriptCode start='\*' end='\*'

syn include @refJavascript syntax/javascript.vim
unlet b:current_syntax

syn region  refJavascriptSampleCode start='^    ' end='^$'
  \ contains=@refJavascript,refJavascriptConceal

syn include @refHtml syntax/html.vim
unlet b:current_syntax

syn region  refJavascriptSampleHtml start='\n    \s*<' end='^$'
  \ contains=@refHtml,refJavascriptConceal

syn region  refJavascriptKeyword oneline concealends
  \ matchgroup=refJavascriptConceal start='^|' end='|$'

" Highlight Group Link
hi def link refJavascriptKeyword    Tag
hi def link refJavascriptVar        Identifier
hi def link refJavascriptCode       Special

let b:current_syntax = 'ref-javascript'

" s:cpo_save {{{1
let &cpo = s:cpo_save
unlet s:cpo_save
"}}}

" vim: set et sts=4 sw=4 wrap:
