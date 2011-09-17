" ============================================================================
" File:         autoload/ref/kotobank.vim
" Author:       mojako <moja.ojj@gmail.com>
" URL:          https://github.com/mojako/ref-sources.vim
" Last Change:  2011-09-16
" ============================================================================

scriptencoding utf-8

" s:cpo_save {{{1
let s:cpo_save = &cpo
set cpo&vim
"}}}

" options {{{1
if !exists('g:ref_kotobank_auto_resize')
    let g:ref_kotobank_auto_resize =
      \ exists('g:ref_auto_resize') ? g:ref_auto_resize : 0
endif

if !exists('g:ref_kotobank_auto_resize_min_size')
    let g:ref_kotobank_auto_resize_min_size =
      \ exists('g:ref_auto_resize_min_size') ? g:ref_auto_resize_min_size : 10
endif

if !exists('g:ref_kotobank_use_cache')
    let g:ref_kotobank_use_cache =
      \ exists('g:ref_use_cache') ? g:ref_use_cache : 0
endif
"}}}

let s:source = {'name': 'kotobank'}

" s:source.available() {{{1
" ====================
function! s:source.available()
    return executable('curl')
endfunction

" s:source.get_body( <query> ) {{{1
" ============================
function! s:source.get_body(query)
    let query = refsrc#iconv(a:query, &enc, 'utf-8')

    " キャッシュが無効な場合、<query>を検索して返す {{{2
    if !g:ref_kotobank_use_cache
        return refsrc#iconv(s:get_body(query), 'utf-8', &enc)
    endif

    " <query>のキャッシュが存在する場合、それを返す {{{2
    let cache_name = tolower(query)
    let cache = self.cache(cache_name)
    if type(cache) == type([])
        return refsrc#iconv(cache, 'utf-8', &enc)
    endif

    " 存在しない場合、<query>を検索してキャッシュする {{{2
    let body = s:get_body(query)
    if body != ''
        call self.cache(cache_name, [body], 1)
    endif
    "}}}

    return refsrc#iconv(body, 'utf-8', &enc)
endfunction

" s:source.get_keyword() {{{1
" ======================
function! s:source.get_keyword()
    let url = ref#get_text_on_cursor('https\?://\S\+')
    if url != ''
        if globpath(&rtp, 'autoload/openbrowser.vim') != ''
            call openbrowser#open(url)
        endif
        return ''
    endif

    return expand('<cword>')
endfunction

" s:source.opened( <query> ) {{{1
" ==========================
function! s:source.opened(query)
    " 自動リサイズ
    if g:ref_kotobank_auto_resize
        call refsrc#autoResizeRefWindow(g:ref_kotobank_auto_resize_min_size)
    endif
endfunction
"}}}

function! ref#kotobank#define()
    return copy(s:source)
endfunction

" s:get_body( <query> ) {{{1
" =====================
function! s:get_body(query)
    " <query>の検索結果を取得 {{{2
    let body = refsrc#get_url('http://kotobank.jp/search/result', {
      \ 'q': a:query
      \ })

    " 一致する結果がないとき、空の文字列を返す {{{2
    if body =~# '<div id="notFound">'
        return ''
    endif

    " 改行とタブを削除 {{{2
    let body = substitute(body, '[\n\r\t]', '', 'g')

    " 検索結果部分を抽出 {{{2
    let body = matchstr(body,
      \ '<ul class="word_dic">\zs.\{-}\ze</ul>\%(<ul class="word_dic">\)\@!')

    " 不要な部分を削除 {{{2
    let body = substitute(body, '<li class="ad">.\{-}</li>', '', 'g')
    let body = substitute(body, '<li class="source">.\{-}</li>', '', 'g')
    let body = substitute(body, '<li class="word_open">.\{-}</li>', '', 'g')

    " <br>, <li>タグを改行に変換 {{{2
    let body = substitute(body, '<\%(br\|li\)\%(\s[^>]*\)\?>', '\n', 'g')

    " <b>タグを置換 {{{2
    let body = substitute(body, '\n\zs<b>\s*\(.\{-}\)\s*</b>\s*', '*\1* ', 'g')
    let body = substitute(body, '<b>\s*\(.\{-}\)\s*</b>', '*\1*', 'g')

    " すべてのタグを削除 {{{2
    let body = substitute(body, '<[^>]*>', '', 'g')

    " 文字参照を置換 {{{2
    let body = refsrc#replaceHtmlEntities(body)

    " 空行を詰める {{{2
    let body = substitute(body, '\s\+\n', '\n', 'g')
    let body = substitute(body, '^\n\+', '', 'g')
    let body = substitute(body, '\n\+\s*$', '', 'g')
    let body = substitute(body, '\n\{3,}', '\n\n', 'g')

    " 変換されたデータを返す {{{2
    return body
    "}}}
endfunction
"}}}

" s:cpo_save {{{1
let &cpo = s:cpo_save
unlet s:cpo_save
"}}}

" vim: set et sts=4 sw=4 wrap:
