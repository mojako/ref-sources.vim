" ============================================================================
" File:         autoload/ref/jquery.vim
" Author:       mojako <moja.ojj@gmail.com>
" URL:          https://github.com/mojako/ref-sources.vim
" Last Change:  2011-08-25
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

if !exists('g:ref_jquery_use_cache') && !exists('g:ref_use_cache')
    let g:ref_jquery_use_cache = 0
endif

if !exists('g:ref_jquery_use_webapi') && !exists('g:ref_use_webapi')
    let g:ref_jquery_use_webapi = globpath(&rtp, 'autoload/http.vim') != ''
endif
"}}}

let s:source = {'name': 'jquery', 'version': 102}

" s:source.available() {{{1
" ====================
function! s:source.available()
    return executable('curl') || isdirectory(g:ref_jquery_doc_path)
endfunction

" s:source.call( <query> ) {{{1
" ========================
function s:source.call(query)
    " Webページを取得 {{{2
    if empty(g:ref_jquery_doc_path)
        let url = 'http://jqapi.com/' . a:query
        let ret = s:get_url(url)
    else
        let ret = join(readfile(
              \ g:ref_jquery_doc_path . '/' . a:query), "\n")
    endif

    " 改行とタブを削除 {{{2
    let ret = join(map(split(ret, '\ze</\?pre[> ]'),
      \ 'v:val =~ "^<pre"
      \     ? "\n" .  substitute(v:val, ''^\|\n\zs'', "    ", "g") . "\n"
      \     : substitute(v:val, ''[\n\r\t]'', "", "g")'),
      \ '')

    " 不要な部分を削除 {{{2
    let ret = substitute(ret, '<div class="entry-content">.\{-}</div>', '', 'g')

    " optionを置換 {{{2
    let ret = substitute(ret,
      \ '<h5 class="option">\(.\{-}\)\%(<span class="type">\(.\{-}\)</span>\)\?</h5>',
      \ '\n[\1\] \2', 'g')

    " <div>, <h1> - <h6>, <li>, <p>タグを改行に変換 {{{2
    let ret = substitute(ret,
      \ '<\%(div\|/\?h[1-6]\|/\?li\|/\?p\)\%(\s[^>]*\)\?>', '\n', 'g')

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
    let ret = substitute(ret, '\n\{3,}', '\n\n', 'g')
    "}}}2

    return ret
endfunction

" s:source.complete( <query> ) {{{1
" ============================
function! s:source.complete(query)
    let query = self.normalize(a:query)
    return sort(filter(keys(self.index()), 'v:val =~? ''\V' . query . ''''))
endfunction

" s:source.get_body( <query> ) {{{1
" ============================
function! s:source.get_body(query)
    " <query>とマッチするインデックスを探す {{{2
    let match = filter(keys(self.index()), 'v:val =~? ''\V' . a:query . '''')

    " マッチが1件の場合、そのページを返す {{{2
    if len(match) == 1
        return {
              \ 'body': s:get_option('use_cache')
              \     ? self.cache(self._index[match[0]], self)
              \     : self.call(self._index[match[0]]),
              \ 'query': match[0]
              \ }
    endif

    " マッチに<query>と一致するものがある場合、そのページを返す {{{2
    let idx = index(map(copy(match),
      \ 'substitute(v:val, ''()\| .*'', '''', ''g'')'), a:query, 0, 1)
    if idx >= 0
        return {
          \ 'body': s:get_option('use_cache')
          \     ? self.cache(self._index[match[idx]], self)
          \     : self.call(self._index[match[idx]]),
          \ 'query': match[idx]
          \ }
    endif

    " それ以外の場合、マッチのリストを返す {{{2
    return {'body': sort(match), 'query': a:query . '?'}
    "}}}2
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
    " インデックスが存在しない場合、キャッシュからロードする {{{2
    if !exists('self._index')
        let self._index = s:get_option('use_cache')
          \ ? s:list2dict(self.cache('_index', [])) : {}
    endif

    " インデックスが空の場合、インデックスを生成し、キャッシュする {{{2
    if empty(self._index)
        if empty(g:ref_jquery_doc_path)
            let html = s:get_url('http://jqapi.com/navigation.html')
        else
            let html = join(readfile(g:ref_jquery_doc_path
              \ . '/navigation.html'), "\n")
        endif

        for item in split(html, '<li class=''sub''>')[1:]
            let name = matchstr(item,
              \ '<span class=''searchable''>\zs.\{-}\ze</span>')
            let link = matchstr(item, '<a href=''\zs.\{-}\ze''>')
            if link != ''
                let self._index[name] = substitute(link, '^/\~\([^/]\+\)',
                  \ '\=toupper(submatch(1))', '')
            endif
        endfor

        " インデックスをキャッシュ
        if s:get_option('use_cache')
            call self.cache('_index', s:dict2list(self._index), 1)
        endif
    endif

    " <query>と一致するインデックスの内容を返す {{{2
    if a:0
        return get(self._index, a:1, '')
    " 引数のない場合、インデックス全体を返す {{{2
    else
        return self._index
    endif
    "}}}2
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
    unlet b:current_syntax
    syn region  refJquerySampleCode start='^    ' end='^$'
      \ contains=@refJavascript,refJqueryConceal

    syn include @refHtml syntax/html.vim
    unlet b:current_syntax
    syn region  refJquerySampleHtml start='\n    \s*<' end='^$'
      \ contains=@refHtml,refJqueryConceal

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

" s:dict2list( <dictionary> ) {{{1
" ===========================
function! s:dict2list(dict)
    let ret = []
    for [key, value] in items(a:dict)
        call add(ret, key)
        call add(ret, value)
    endfor
    return ret
endfunction

" s:get_option( <option_name> ) {{{1
" =============================
function! s:get_option(optname)
    return exists('g:ref_{s:source.name}_{a:optname}')
      \ ? g:ref_{s:source.name}_{a:optname}
      \ : exists('g:ref_{a:optname}') ? g:ref_{a:optname} : 0
endfunction

" s:get_url( <url> ) {{{1
" ==================
function! s:get_url(url)
    if s:get_option('use_webapi')
        return http#get(a:url).content
    else
        return ref#system(['curl', '-kLs', a:url]).stdout
    endif
endfunction

" s:list2dict( <array> ) {{{1
" ======================
function! s:list2dict(array)
    let ret = {}
    let len = len(a:array)
    let i = 0
    while i < len
        let ret[a:array[i]] = get(a:array, i + 1, '')
        let i = i + 2
    endwhile
    return ret
endfunction
"}}}1

if s:source.available() && s:get_option('use_cache')
  \ && ref#cache(s:source.name, '_version', [0])[0] < 102
    call ref#rmcache(s:source.name)
    call ref#cache(s:source.name, '_version', [s:source.version])
endif

" s:cpo_save {{{1
let &cpo = s:cpo_save
unlet s:cpo_save
"}}}

" vim: set et sts=4 sw=4 wrap:
