" ============================================================================
" File:         autoload/ref/wikipedia.vim
" Author:       mojako <moja.ojj@gmail.com>
" URL:          https://github.com/mojako/ref-sources.vim
" Last Change:  2011-09-17
" ============================================================================

scriptencoding utf-8

" s:cpo_save {{{1
let s:cpo_save = &cpo
set cpo&vim
"}}}

" options {{{1
if !exists('g:ref_wikipedia_lang')
    let g:ref_wikipedia_lang = matchstr(v:lang, '^\a\+')
endif
"}}}

let s:source = {'name': 'wikipedia'}

" s:source.available() {{{1
" ====================
function! s:source.available()
    return executable('curl')
endfunction

" s:source.complete( <query> ) {{{1
" ============================
function! s:source.complete(query)
    let q = split(refsrc#iconv(a:query, &enc, 'utf-8'), '#')
    let api = 'http://' . self._lang . '.wikipedia.org/w/api.php'

    let result = refsrc#get_url(api, {
      \ 'action': 'opensearch',
      \ 'format': 'json',
      \ 'search':  q[0],
      \ })

    return result != '' ? refsrc#iconv(eval(result)[1], 'utf-8', &enc) : []
endfunction

" s:source.get_body( <query> ) {{{1
" ============================
function! s:source.get_body(query)
    let q = split(refsrc#iconv(a:query, &enc, 'utf-8'), '#')

    " MediaWiki APIを叩く {{{2
    let api = 'http://' . self._lang . '.wikipedia.org/w/api.php'
    let result = refsrc#get_url(api, {
      \ 'action'    : 'query',
      \ 'format'    : 'json',
      \ 'redirects' :  1,
      \ 'titles'    :  q[0],
      \ 'prop'      : 'revisions',
      \ 'rvprop'    : 'content',
      \ })

    if result == ''
        return ''
    endif

    let json = eval(result)['query']

    " 一致する結果がないとき、空の結果を返す {{{2
    let pageid = keys(json.pages)[0]
    if pageid < 0
        return ''
    endif

    " 結果を整形 {{{2
    let title = json.pages[pageid].title
    let body = substitute(json.pages[pageid].revisions[0]['*'],
      \ '\r\n\?', '\n', 'g')

    " __TOC__, __NOTOC__を削除 {{{3
    let body = substitute(body, '\n__\%(NO\)\?TOC__\n', '\n', '')

    " コメントを削除 {{{3
    let body = substitute(body, '<!--.\{-}-->', '', 'g')

    " テンプレートを削除 {{{3
    let after = substitute(body, '{{[^{]\{-}\}}', '|×|', 'g')
    while body != after
        let body = after
        let after = substitute(body, '{{[^{]\{-}\}}', '|×|', 'g')
    endwhile

    " 表を削除 {{{3
    let after = substitute(body, '{|[^{]\{-}|}', '|×|', 'g')
    while body != after
        let body = after
        let after = substitute(body, '{|[^{]\{-}|}', '|×|', 'g')
    endwhile

    let body = substitute(body, '\%(^\|\n\)|×|\ze\%(\n\|$\)', '', 'g')

    " 名前空間付きのリンクを削除 {{{3
    let body = substitute(body,
      \ '\%(^\|\n\)\zs\[\[[^]]*:.\{-}\]\]\ze\%(\n\|$\)', '', 'g')

    let body = substitute(body,
      \ '\[\[:\?[^\]:]\+:\([^]|]\+\)\%(|\(.\{-}\)\)\?\]\]',
      \ '\=submatch(2) != '''' ? submatch(2) : submatch(1)', 'g')

    " マークアップを簡略化 {{{3
    let body = substitute(body, '\%(^\|\n\)[*#:]\+\zs\s*', ' ', 'g')
    let body = substitute(body, '\%(^\|\n\)[*#:]\+\zs \[', '[', 'g')

    let body = substitute(body, '\(''\{2,5}\)\(.\{-}\)\1', '''''\2''''', 'g')
    let body = substitute(body, '\[\[\([^]#]*\)\(#.\{-}\)\?\]\]',
      \ '\="[" . submatch(1) . s:decode_fragment(submatch(2)) . "]"', 'g')

    let body = substitute(body, '\n\zs\(=\{2,4}\)\s*\(.\{-}\)\s*\1\ze\n',
      \ '\n\1 \2 \1\n', 'g')

    " <ref>タグを変換 {{{3
    let body = substitute(body, '<ref[^>]*>\([^<].\{-}\)</ref>',
      \ '\&lt;^\1\&gt;', 'g')

    " <div>, <p>, <pre>タグを改行に変換 {{{3
    let body = substitute(body,
      \ '</\?\%(div\|p\|pre\)\%(\s[^>]*\)\?>\s*', '\n', 'g')

    " <br>タグを改行に変換 {{{3
    let body = substitute(body, '<br\s*\/\?>', '\n', 'g')

    " すべてのタグを削除 {{{3
    let body = substitute(body, '<[^>]*>\n\?\s*', '', 'g')

    " 文字参照を置換 {{{3
    let body = refsrc#replaceHtmlEntities(body)

    " 空行を詰める {{{3
    let body = substitute(body, '\s\+\n', '\n', 'g')
    let body = substitute(body, '^\n\+', '', 'g')
    let body = substitute(body, '\n\+\s*$', '', 'g')
    let body = substitute(body, '\n\{3,}', '\n\n', 'g')
    "}}}2

    return refsrc#iconv({
      \ 'query':    len(q) > 1 ? title . '#' . q[1] : title,
      \ 'body':     body,
      \ }, 'utf-8', &enc)
endfunction

function! s:test(query)
    return a:query
endfunction

" s:source.get_keyword() {{{1
" ======================
function! s:source.get_keyword()
    let kwd = ref#get_text_on_cursor('\[\zs.\{-}\ze\]')
    if kwd != ''
        let url = matchstr(kwd, '^https\?://\S\+')
        if url != ''
            if globpath(&rtp, 'autoload/openbrowser.vim') != ''
                call openbrowser#open(url)
            endif
            return ''
        endif
        let kwd = matchstr(kwd, '^[^|]*')
        if kwd =~ '^#'
            return ''
        endif
        return kwd
    endif
    return expand('<cword>')
endfunction

" s:source.opened( <query> ) {{{1
" ==========================
function! s:source.opened(query)
    setl syntax=ref-wikipedia

    let jump = matchstr(refsrc#iconv(a:query, &enc, 'utf-8'), '#\zs.*$')
    if jump != ''
        let jump = substitute(jump, '_', '[ _]', 'g')
        call search('== ' . jump . ' ==')
    endif
endfunction
"}}}

function! ref#wikipedia#define()
    if type(g:ref_wikipedia_lang) == type('')
        let s:source._lang = g:ref_wikipedia_lang
        return copy(s:source)
    elseif type(g:ref_wikipedia_lang) == type([])
        let s:source._lang = g:ref_wikipedia_lang[0]
        let ret = [copy(s:source)]
        for lang in g:ref_wikipedia_lang[1:]
            let s:source.name = 'wikipedia_' . lang
            let s:source._lang = lang
            call add(ret, copy(s:source))
        endfor
        return ret
    elseif type(g:ref_wikipedia_lang) == type({})
        let ret = []
        for [name, lang] in items(g:ref_wikipedia_lang)
            let s:source.name = name
            let s:source._lang = lang
            call add(ret, copy(s:source))
        endfor
        return ret
    endif
endfunction

" s:decode_fragment( <string> ) {{{1
" =============================
function! s:decode_fragment(str)
    return refsrc#decodeURIComponent(substitute(a:str, '\.\ze\x\x', '%', 'g'))
endfunction
"}}}

" s:cpo_save {{{1
let &cpo = s:cpo_save
unlet s:cpo_save
"}}}

" vim: set et sts=4 sw=4 wrap:
