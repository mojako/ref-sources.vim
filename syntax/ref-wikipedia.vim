" ============================================================================
" Language:     ref-wikipedia
" File:         syntax/ref-wikipedia.vim
" Author:       mojako <moja.ojj@gmail.com>
" URL:          https://github.com/mojako/ref-sources.vim
" Last Change:  2011-09-17
" ============================================================================

" s:cpo_save {{{1
let s:cpo_save = &cpo
set cpo&vim
"}}}

if exists('b:current_syntax')
    finish
endif

syn match   refWikipediaHead    '^==.\+==$'
syn match   refWikipediaHead2   '^===.\+===$'
syn match   refWikipediaHead3   '^====.\+====$'

syn match   refWikipediaIndent  '^:\+' conceal transparent
syn match   refWikipediaList    '^[*#]\+\ze[ \['']'

syn region  refWikipediaBold oneline concealends
  \ matchgroup=refWikipediaConceal start="''" end="''"
  \ contains=refWikipediaLink

syn region  refWikipediaLink oneline concealends
  \ matchgroup=refWikipediaConceal start='\[' end='\]'
  \ contains=refWikipediaBold,refWikipediaLinkName,refWikipediaLinkURL

syn match   refWikipediaLinkName    '\%(\[\)\@<=[^\]|]\+|' contained
syn match   refWikipediaLinkURL     '\%(\[\)\@<=https\?://[^] ]\+' contained

syn match   refWikipediaDeleted     '|×|'

" Highlight Group Link
hi def link refWikipediaHead        Title
hi def link refWikipediaHead2       Title
hi def link refWikipediaHead3       Title

hi def link refWikipediaIndent      Ignore
hi def link refWikipediaList        Identifier

hi def link refWikipediaBold        Type
hi def link refWikipediaLink        Constant

hi def link refWikipediaLinkName    Comment
hi def link refWikipediaLinkURL     Underlined

hi def link refWikipediaDeleted     SpecialKey

let b:current_syntax = 'ref-wikipedia'

" s:cpo_save {{{1
let &cpo = s:cpo_save
unlet s:cpo_save
"}}}

" vim: set et sts=4 sw=4 wrap:
