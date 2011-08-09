" ============================================================================
" File:         autoload/ref/kotobankej.vim
" Author:       mojako <moja.ojj@gmail.com>
" URL:          https://github.com/mojako/ref-sources.vim
" Last Change:  2011-08-09
" ============================================================================

scriptencoding utf-8

" s:cpo_save {{{1
let s:cpo_save = &cpo
set cpo&vim
"}}}

" options {{{1
if !exists('g:ref_kotobankej_auto_resize')
    let g:ref_kotobankej_auto_resize = 0
endif

if !exists('g:ref_kotobankej_auto_resize_min_size')
    let g:ref_kotobankej_auto_resize_min_size = 10
endif

if !exists('g:ref_kotobankej_use_webapi')
    let g:ref_kotobankej_use_webapi = globpath(&rtp, 'autoload/http.vim') != ''
endif
"}}}

let s:source = {'name': 'kotobankej'}

" s:source.available() {{{1
" ====================
function! s:source.available()
    return executable('curl')
endfunction

" s:source.get_body( <query> ) {{{1
" ============================
function! s:source.get_body(query)
    let url = 'http://kotobank.jp/ejsearch/result?q='
      \ . s:encodeURIComponent(s:iconv(a:query, &enc, 'utf-8')) . '&t=2'

    " Webページを取得 {{{2
    if g:ref_kotobankej_use_webapi
        let ret = http#get(url).content
    else
        let ret = system("curl -kLs '" . url . "'")
    endif

    " 一致する結果がないとき、空の結果を返す {{{2
    if ret =~# '<p id="zero">' || ret =~# '<div id="EJunitList">'
        return ''
    endif
    "}}}2

    " 改行とタブを削除 {{{2
    let ret = substitute(ret, '[\n\r\t]', '', 'g')

    " 検索結果部分を抽出 {{{2
    let ret = matchstr(ret,
      \ '<div class="wordExpound">\zs.*\ze<!-- /wordExpound -->')

    " 不要な部分を削除 {{{2
    let ret = substitute(ret, '<ul class="tree">.\{-}</ul>', '', 'g')
    let ret = substitute(ret, '<div class="short">.\{-}</div>', '', 'g')
    let ret = substitute(ret, '<div class="sponsorLink">.\{-}</div>', '', 'g')
    let ret = substitute(ret, '<dl class="adapted">.\{-}</dl>', '', 'g')
    let ret = substitute(ret, '<div class="more">.\{-}</div>', '', 'g')

    " 辞書名 {{{2
    let ret = substitute(ret, '<li class="title">\(.\{-}\)</li>', '\1\n', 'g')

    " <br>, <li> タグを改行に変換 {{{2
    let ret = substitute(ret, '<\%(br\|li\)\%(\s[^>]*\)\?>', '\n', 'g')

    " <b> タグを置換 {{{2
    let ret = substitute(ret, '<b>\s*\(.\{-}\)\s*</b>', '**\1**', 'g')

    " 発音 {{{2
    let ret = substitute(ret, '<span class="hatsuon">', ' ', 'g')

    " 用例 {{{2
    let ret = substitute(ret, '<span class="illTxt">', '» ', 'g')

    " 外字画像をUnicode文字に変換 {{{2
    let ret = substitute(ret, '<img name="G150"[^>]*>', 'ʃ', 'g')
    let ret = substitute(ret, '<img name="G173"[^>]*>', 'ʒ', 'g')
    let ret = substitute(ret, '<img name="G477"[^>]*>', 'ː', 'g')
    let ret = substitute(ret, '<img name="8157"[^>]*>', 'ŋ', 'g')
    let ret = substitute(ret, '<img name="\(.\{-}\)"[^>]*>', '(\1)', 'g')

    " すべてのタグを削除 {{{2
    let ret = substitute(ret, '<[^>]*>', '', 'g')

    " 微調整 {{{2
    let ret = substitute(ret, '\n\*\*.\{-}\*\*\zs\s*', '\t', 'g')

    " 文字参照を置換 {{{2
    let ret = substitute(ret, '&#\(\d\+;\)', '\=nr2char(submatch(1))', 'g')
    let ret = substitute(ret, '&#x\(\x\+\);',
      \ '\=nr2char("0x" . submatch(1))', 'g')

    let ret = substitute(ret, '&gt;', '>', 'g')
    let ret = substitute(ret, '&lt;', '<', 'g')
    let ret = substitute(ret, '&quot;', '"', 'g')
    let ret = substitute(ret, '&apos;', "'", 'g')
    let ret = substitute(ret, '&ndash;', '-', 'g')
    let ret = substitute(ret, '&dagger;', '†', 'g')
    let ret = substitute(ret, '&theta;', 'θ', 'g')
    let ret = substitute(ret, '&eth;', 'ð', 'g')
    let ret = substitute(ret, '&agrave;', 'à', 'g')
    let ret = substitute(ret, '&aacute;', 'á', 'g')
    let ret = substitute(ret, '&egrave;', 'è', 'g')
    let ret = substitute(ret, '&eacute;', 'é', 'g')
    let ret = substitute(ret, '&igrave;', 'ì', 'g')
    let ret = substitute(ret, '&iacute;', 'í', 'g')
    let ret = substitute(ret, '&ograve;', 'ò', 'g')
    let ret = substitute(ret, '&oacute;', 'ó', 'g')
    let ret = substitute(ret, '&ugrave;', 'ù', 'g')
    let ret = substitute(ret, '&uacute;', 'ú', 'g')
    let ret = substitute(ret, '&nbsp;', '　', 'g')
    let ret = substitute(ret, '&amp;', '\&', 'g')

    " 空行を詰める {{{2
    let ret = substitute(ret, '\s\+\n', '\n', 'g')
    let ret = substitute(ret, '\n\{3,}', '\n\n', 'g')
    let ret = substitute(ret, '^\n\+', '', 'g')
    let ret = substitute(ret, '\n\+$', '', 'g')
    "}}}2

    return s:iconv(ret, 'utf-8', &enc)
endfunction

" s:source.leave() {{{1
" ================
function! s:source.leave()
    syntax clear
endfunction

" s:source.opened( <query> ) {{{1
" ==========================
function! s:source.opened(query)
    setl nolist
    setl conceallevel=2

    call s:syntax()

    if g:ref_kotobankej_auto_resize
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
        if h < g:ref_kotobankej_auto_resize_min_size
            let h = g:ref_kotobankej_auto_resize_min_size
        elseif h > w:old_height
            let h = w:old_height
        endif
        exe 'resize' h
    endif
endfunction
"}}}1

function! ref#kotobankej#define()
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

" s:iconv( <expr>, <from>, <to> ) {{{1
" ===============================
function! s:iconv(expr, from, to)
    if a:from == '' || a:to == '' || a:from ==# a:to
        return a:expr
    endif
    let result = iconv(a:expr, a:from, a:to)
    return result != '' ? result : a:expr
endfunction

" s:syntax() {{{1
" ==========
function! s:syntax()
    syn match  refKotobankDicName '^.*の解説$'
    syn match  refKotobankBold    '\*\*.\{-}\*\*' contains=refKotobankConceal
    syn match  refKotobankExample '^» .*$'

    syn match  refKotobankConceal '\*' contained conceal transparent

    hi def link refKotobankDicName  Type
    hi def link refKotobankBold     Identifier
    hi def link refKotobankExample  Constant
endfunction
"}}}1

" s:cpo_save {{{1
let &cpo = s:cpo_save
unlet s:cpo_save
"}}}

" vim: set et sts=4 sw=4 wrap:
