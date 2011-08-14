" ============================================================================
" File:         autoload/ref/jquery.vim
" Author:       mojako <moja.ojj@gmail.com>
" URL:          https://github.com/mojako/ref-sources.vim
" Last Change:  2011-08-14
" ============================================================================

scriptencoding utf-8

" s:cpo_save {{{1
let s:cpo_save = &cpo
set cpo&vim
"}}}

" options {{{1
if !exists('g:ref_jquery_doc_path')
    let g:ref_jquery_doc_path = ''
endif

if !exists('g:ref_jquery_use_cache')
    let g:ref_jquery_use_cache = 0
endif

if !exists('g:ref_use_webapi')
    let g:ref_use_webapi = globpath(&rtp, 'autoload/http.vim') != ''
endif
"}}}

let s:source = {'name': 'jquery', 'version': 100}

" s:source.available() {{{1
" ====================
function! s:source.available()
    return executable('curl') || isdirectory(g:ref_jquery_doc_path)
endfunction

" s:source.call( <query> ) {{{1
" ========================
function s:source.call(query)
    if a:query ==# '_index'
        if g:ref_jquery_doc_path
            let html = join(fileread(
              \ g:ref_jquery_doc_path . s:get_path('/navigation.html')), '\n')
        else
            let html = s:get_url('http://jqapi.com/navigation.html')
        endif

        let ret = []
        for item in split(html, '<li class=''sub''>')[1:]
            call add(ret, matchstr(item,
              \ '<span class=''searchable''>\zs.\{-}\ze</span>'))
            call add(ret, matchstr(item, '<a href=''\zs.\{-}\ze''>'))
        endfor

        return ret
    endif

    " Webページを取得 {{{2
    if g:ref_jquery_doc_path
        let ret = join(fileread(
              \ g:ref_jquery_doc_path . s:get_path(a:query)), '\n')
    else
        let url = 'http://jqapi.com/' . a:query
        let ret = s:get_url(url)
    endif

    " 改行とタブを削除 {{{2
    let ret = join(map(split(ret, '\ze</\?pre[> ]'),
      \ 'v:val =~ "^<pre" ? v:val : substitute(v:val, ''[\n\r\t]'', "", "g")'),
      \ '')

    " 不要な部分を削除 {{{2
    let ret = substitute(ret, '<div class="entry-content">.\{-}</div>', '', 'g')

    " optionを置換 {{{2
    let ret = substitute(ret,
      \ '<h5 class="option">\(.\{-}\)\%(<span class="type">\(.\{-}\)</span>\)\?</h5>',
      \ '\n[\1\] \2', 'g')

    " <div>, <h1> - <h6>, <li>, <p>タグを改行に変換 {{{2
    let ret = substitute(ret,
      \ '<\%(div\|/\?h[1-6]\|li\|/\?p\)\%(\s[^>]*\)\?>', '\n', 'g')

    " <pre>タグを置換 {{{2
    let ret = substitute(ret, '<pre\%(\s[^>]*\)\?>\(.\{-}\)</pre>',
      \ '\n```\n\1\n```\n', 'g')

    " <code>タグを置換 {{{2
    let ret = substitute(ret, '<code>\(.\{-}\)</code>', '`\1`', 'g')

    " <strong>タグを置換 {{{2
    let ret = substitute(ret,
      \ '\n\zs<strong>\s*\(.\{-}\)\s*</strong>\s*', '\*\1\* ', 'g')
    let ret = substitute(ret, '<strong>\s*\(.\{-}\)\s*</strong>', '*\1*', 'g')

    " versionAddedを置換 {{{2
    let ret = substitute(ret,
      \ '<span class="versionAdded">.\{-}</span>\zs', '\n', 'g')

    " すべてのタグを削除 {{{2
    let ret = substitute(ret, '<[^>]*>', '', 'g')

    " 文字参照を置換 {{{2
    let ret = substitute(ret, '&#\(\d\+\);', '\=nr2char(submatch(1))', 'g')
    let ret = substitute(ret, '&#x\(\x\+\);',
      \ '\=nr2char("0x" . submatch(1))', 'g')

    let ret = substitute(ret, '&gt;', '>', 'g')
    let ret = substitute(ret, '&lt;', '<', 'g')
    let ret = substitute(ret, '&quot;', '"', 'g')
    let ret = substitute(ret, '&apos;', "'", 'g')
    let ret = substitute(ret, '&nbsp;', '　', 'g')
    let ret = substitute(ret, '&amp;', '\&', 'g')

    " 空行を詰める {{{2
    let ret = substitute(ret, '\s\+\n', '\n', 'g')
    let ret = substitute(ret, '^\n\+', '', 'g')
    let ret = substitute(ret, '\n\+\s*$', '', 'g')
    "}}}2

    return split(ret, '\n\zs\n\+')
endfunction

" s:source.complete( <query> ) {{{1
" ============================
function! s:source.complete(query)
    let query = self.normalize(a:query)
    let index = self.index()

    let ret = []
    for name in keys(index)
        if name =~? query
            call add(ret, name)
        endif
    endfor

    return sort(ret)
endfunction

" s:source.get_body( <query> ) {{{1
" ============================
function! s:source.get_body(query)
    let index = self.index()

    let match = []
    for [key, value] in items(index)
        if key ==? a:query || substitute(key, '()\| .*', '', 'g') ==? a:query
            return {
              \ 'body': g:ref_jquery_use_cache
              \     ? self.cache(value, self)
              \     : self.call(value),
              \ 'query': key
              \ }

        elseif key =~? a:query
            call add(match, key)
        endif
    endfor

    if len(match) == 1
        return {
              \ 'body': g:ref_jquery_use_cache
              \     ? self.cache(index[match[0]], self)
              \     : self.call(index[match[0]]),
              \ 'query': match[0]
              \ }
    endif

    return {'body': sort(match), 'query': a:query . '?'}
endfunction

" s:source.get_keyword() {{{1
" ======================
function! s:source.get_keyword()
    let isk_save = &l:isk
    setlocal isk=48-57,65-90,97-122
    let kwd = expand('<cword>')

    setlocal isk=36,45,46,48-58,65-90,97-122
    let kwd = matchstr(expand('<cword>'),
      \ '\%(\$\.\|jQuery\.\|event\.\|:\|\.\)\?' . kwd)
    let &l:isk = isk_save
    return kwd
endfunction

" s:source.index() {{{1
" ================
function s:source.index()
    if !exists('self._index')
        if g:ref_jquery_use_cache
            let array = self.cache('_index', self)
        else
            let array = self.call('_index')
        endif

        let self._index = {}
        let len = len(array)
        let i = 0
        while i < len
            let self._index[array[i]] = array[i+1]
            let i = i + 2
        endwhile
    endif

    return self._index
endfunction

" s:source.leave() {{{1
" ================
function! s:source.leave()
    syntax clear
endfunction

" s:source.normalize( <query> ) {{{1
" =============================
function! s:source.normalize(query)
    return substitute(a:query, '^\$\.', 'jQuery.', '')
endfunction

" s:source.opened( <query> ) {{{1
" ==========================
function! s:source.opened(query)
    " syntax coloring {{{2
    syn match   refJqueryOptionName '^\[.\{-}\]'
    syn match   refJqueryBold       '\*.\{-}\*' contains=refJqueryConceal
    syn match   refJqueryCode       '`.\{-}`' contains=refJqueryConceal

    syn match   refJqueryConceal    '\*' contained conceal transparent
    syn match   refJqueryConceal    '`' contained conceal transparent

    if globpath(&rtp, 'syntax/jquery.vim') != ''
        syn include @refJavascript syntax/jquery.vim
    else
        syn include @refJavascript syntax/javascript.vim
    endif
    syn region  refJquerySampleCode start='^```$' end='^```$' keepend
      \ contains=@refJavascript,refJqueryConceal

    hi def link refJqueryOptionName Type
    hi def link refJqueryBold       Identifier
    hi def link refJqueryCode       Statement
    "}}}2
endfunction
"}}}1

function! ref#jquery#define()
    return copy(s:source)
endfunction

" s:get_path( <path> ) {{{1
" ====================
function! s:get_path(path)
    return exists('+shellslash') && &shellslash
      \ ? substitute(a:path, '/', '\\', 'g')
      \ : a:path
endfunction

" s:get_url( <url> ) {{{1
" ==================
function! s:get_url(url)
    if g:ref_use_webapi
        return http#get(a:url).content
    else
        return ref#system(['curl', '-kLs', a:url]).stdout
    endif
endfunction
"}}}1

if s:source.available() && g:ref_jquery_use_cache
  \ && ref#cache(s:source.name, '_version', [0])[0] < 100
    call ref#rmcache(s:source.name)
    call ref#cache(s:source.name, '_version', [s:source.version])
endif

" s:cpo_save {{{1
let &cpo = s:cpo_save
unlet s:cpo_save
"}}}

" vim: set et sts=4 sw=4 wrap:
