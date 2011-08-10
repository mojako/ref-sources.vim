" ============================================================================
" File:         autoload/ref/kotobank.vim
" Author:       mojako <moja.ojj@gmail.com>
" URL:          https://github.com/mojako/ref-sources.vim
" Last Change:  2011-08-10
" ============================================================================

scriptencoding utf-8

" s:cpo_save {{{1
let s:cpo_save = &cpo
set cpo&vim
"}}}

" options {{{1
if !exists('g:ref_kotobank_auto_resize')
    let g:ref_kotobank_auto_resize = 0
endif

if !exists('g:ref_kotobank_auto_resize_min_size')
    let g:ref_kotobank_auto_resize_min_size = 10
endif

if !exists('g:ref_kotobank_use_cache')
    let g:ref_kotobank_use_cache = 0
endif

if !exists('g:ref_use_webapi')
    let g:ref_use_webapi = globpath(&rtp, 'autoload/http.vim') != ''
endif
"}}}

let s:source = {'name': 'kotobank', 'version': 100}

" s:source.available() {{{1
" ====================
function! s:source.available()
    return executable('curl')
endfunction

" s:source.call( <query> ) {{{1
" ========================
function! s:source.call(query)
    let url = 'http://kotobank.jp/search/result?q=' . a:query

    " Webページを取得 {{{2
    let ret = s:get_url(url)

    " 一致する結果がないとき、空の結果を返す {{{2
    if ret =~# '<div id="notFound">'
        return ''
    endif
    "}}}2

    " 改行とタブを削除 {{{2
    let ret = substitute(ret, '[\n\r\t]', '', 'g')

    " 検索結果部分を抽出 {{{2
    let ret = matchstr(ret,
      \ '<ul class="word_dic">\zs.\{-}\ze</ul>\%(<ul class="word_dic">\)\@!')

    " 不要な部分を削除 {{{2
    let ret = substitute(ret, '<li class="ad">.\{-}</li>', '', 'g')
    let ret = substitute(ret, '<li class="source">.\{-}</li>', '', 'g')
    let ret = substitute(ret, '<li class="word_open">.\{-}</li>', '', 'g')

    " <br>, <li> タグを改行に変換 {{{2
    let ret = substitute(ret, '<br />&nbsp;<br />', '\n', 'g') " 微調整
    let ret = substitute(ret, '<\%(br\|li\)\%(\s[^>]*\)\?>', '\n', 'g')

    " <b> タグを置換 {{{2
    let ret = substitute(ret, '<b>\s*\(.\{-}\)\s*</b>', '*\1*', 'g')

    " すべてのタグを削除 {{{2
    let ret = substitute(ret, '<[^>]*>', '', 'g')

    " 微調整 {{{2
    let ret = substitute(ret, '\n\*\*.\{-}\*\*\zs\s*', '\t', 'g')

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
    let ret = substitute(ret, '\n\+$', '', 'g')
    "}}}2

    return split(ret, '\n\zs\n\+')
endfunction

" s:source.get_body( <query> ) {{{1
" ============================
function! s:source.get_body(query)
    let q = s:encodeURIComponent(s:iconv(a:query, &enc, 'utf-8'))

    if g:ref_kotobank_use_cache
        return s:iconv(self.cache(q, self), 'utf-8', &enc)
    else
        return s:iconv(self.call(q), 'utf-8', &enc)
    endif
endfunction

" s:source.leave() {{{1
" ================
function! s:source.leave()
    syntax clear
endfunction

" s:source.opened( <query> ) {{{1
" ==========================
function! s:source.opened(query)
    " syntax coloring {{{2
    syn match  refKotobankDicName '^.*の解説$'
    syn match  refKotobankBold    '\*.\{-}\*' contains=refKotobankConceal

    syn match  refKotobankConceal '\*' contained conceal transparent

    hi def link refKotobankDicName  Type
    hi def link refKotobankBold     Identifier

    " 自動リサイズ {{{2
    if g:ref_kotobank_auto_resize
        if !exists('w:old_height')
            let w:old_height = winheight(0)
        endif
        let w = winwidth(0)
        let i = 1
        let h = 1
        while h < w:old_height
            let line = getline(i)
            if line == ''
                break
            endif
            let h = h + 1 + strdisplaywidth(line) / w
            let i = i + 1
        endwhile
        if h < g:ref_kotobank_auto_resize_min_size
            let h = g:ref_kotobank_auto_resize_min_size
        elseif h > w:old_height
            let h = w:old_height
        endif
        exe 'resize' h
    endif
    "}}}2
endfunction
"}}}1

function! ref#kotobank#define()
    return copy(s:source)
endfunction

" s:encodeURIComponent( <string> ) {{{1
" ================================
function! s:encodeURIComponent(str)
    let ret = ''
    let len = strlen(a:str)
    let i = 0
    while i < len
        if a:str[i] =~# "[0-9A-Za-z._~!'()*-]"
            let ret .= a:str[i]
        elseif a:str[i] == ' '
            let ret .= '+'
        else
            let ret .= printf('%%%02X', char2nr(a:str[i]))
        endif
        let i = i + 1
    endwhile
    return ret
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

" s:iconv( <expr>, <from>, <to> ) {{{1
" ===============================
function! s:iconv(expr, from, to)
    if a:from == '' || a:to == '' || a:from ==? a:to
        return a:expr
    elseif type(a:expr) == type([]) || type(a:expr) == type({})
        return map(a:expr, 's:iconv(v:val, a:from, a:to)')
    endif

    let ret = iconv(a:expr, a:from, a:to)
    return ret != '' ? ret : a:expr
endfunction
"}}}1

if s:source.available() && g:ref_kotobank_use_cache
  \ && ref#cache(s:source.name, '_version', [0])[0] < 100
    call ref#rmcache(s:source.name)
    call ref#cache(s:source.name, '_version', [s:source.version])
endif

" s:cpo_save {{{1
let &cpo = s:cpo_save
unlet s:cpo_save
"}}}

" vim: set et sts=4 sw=4 wrap:
