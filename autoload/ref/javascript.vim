" ============================================================================
" File:         autoload/ref/javascript.vim
" Author:       mojako <moja.ojj@gmail.com>
"               shiwano <shiwano@gmail.com>
" URL:          https://github.com/mojako/ref-sources.vim
" Last Change:  2012-03-16
" ============================================================================

scriptencoding utf-8

" s:cpo_save {{{1
let s:cpo_save = &cpo
set cpo&vim
"}}}

" options {{{1
if !exists('g:ref_javascript_doc_path')
    let g:ref_javascript_doc_path = ''
endif

if !exists('g:ref_javascript_use_cache')
    let g:ref_javascript_use_cache = exists('g:ref_use_cache') ? g:ref_use_cache : 0
endif
"}}}

let s:source = {'name': 'javascript'}

" s:source.available() {{{1
" ====================
function! s:source.available()
    return executable('curl') || isdirectory(g:ref_javascript_doc_path)
endfunction

" s:source.complete( <query> ) {{{1
" ============================
function! s:source.complete(query)
    call self.init()

    let query = self.normalize(a:query)
    return sort(filter(keys(self._index), 'v:val =~? ''\V' . query . ''''))
endfunction

" s:source.get_body( <query> ) {{{1
" ============================
function! s:source.get_body(query)
    call self.init()

    " インデックスから<query>の項目を探す {{{2
    let m = filter(keys(self._index),
      \ 'v:val =~? ''^\V'' . a:query . ''\%(()\)\?\$''')
    if len(m)
        let idx = m[0]
    " 見付からない場合、<query>を含む項目を探す {{{2
    else
        let m = filter(keys(self._index), 'v:val =~? ''\V' . a:query . '''')
        if len(m) == 1
            let idx = m[0]
        else
            " 候補がない、もしくは複数の場合、候補のリストを返す
            return {
              \ 'query' : a:query . '?',
              \ 'body'  : map(sort(m), '''|'' . v:val . ''|'''),
              \ }
        endif
    endif

    " キャッシュが有効な場合の処理 {{{2
    if g:ref_javascript_use_cache
        " 候補のキャッシュが存在する場合、それを返す {{{3
        let cache = self.cache(self._index[idx])
        if type(cache) == type([])
            return {
              \ 'query' : idx,
              \ 'body'  : cache,
              \ }
        endif

        " 存在しない場合、ページを取得してキャッシュする {{{3
        let body = s:get_body(self._index[idx])
        call self.cache(self._index[idx], [body], 1)

        " ページを返す {{{3
        return {
          \ 'query' : idx,
          \ 'body'  : body,
          \ }
        "}}}
    endif

    " キャッシュが無効な場合、ページを取得して返す {{{2
    return {
      \ 'query' : idx,
      \ 'body'  : s:get_body(self._index[idx])
      \ }
    "}}}
endfunction

" s:source.get_keyword() {{{1
" ======================
function! s:source.get_keyword()
    let kwd = ref#get_text_on_cursor('^|\zs.*\ze|$')
    if kwd != ''
        return kwd
    endif

    return ref#get_text_on_cursor('[0-9A-Za-z]\+')
endfunction

" s:source.init() {{{1
" ===============
function s:source.init()
    if has_key(self, '_index')
        return
    endif

    " インデックスをキャッシュからロードする {{{2
    let self._index = {}

    if g:ref_javascript_use_cache
        let cache = self.cache('_index')
        if type(cache) == type([])
            while len(cache) > 1
                let [key, val] = remove(cache, 0, 1)
                let self._index[key] = val
            endwhile
            return
        endif
    endif

    " インデックスを生成する {{{2
    if g:ref_javascript_doc_path == ''
        let result = refsrc#get_url('http://jsref.64p.org/index.json')
    else
        let result = join(readfile(g:ref_javascript_doc_path
          \ . '/index.json'), "\n")
    endif

    let result = substitute(result, '\n', '', 'g')
    let result = substitute(result, 'null', '""', 'g')
    let result = substitute(result, 'false', '0', 'g')
    let result = substitute(result, 'true', '1', 'g')
    let json = eval(result)

    for item in json
        if item.category != 'Misc'
            let self._index[item.title] = item.url
        endif
    endfor

    " キャッシュが有効な場合、インデックスをキャッシュする {{{2
    if g:ref_javascript_use_cache
        let list = []
        for [key, value] in items(self._index)
            call add(list, key)
            call add(list, value)
        endfor
        call self.cache('_index', list, 1)
    endif
    "}}}
endfunction

" s:source.normalize( <query> ) {{{1
" =============================
function! s:source.normalize(query)
    return a:query
endfunction
"}}}

function! ref#javascript#define()
    return copy(s:source)
endfunction

call ref#register_detection('javascript', 'javascript')

" s:get_body( <query> ) {{{1
" =====================
function! s:get_body(query)
    " ページを取得 {{{2
    if g:ref_javascript_doc_path == ''
        let body = refsrc#get_url('http://jsref.64p.org/' . a:query)
    else
        let body = join(readfile(
              \ g:ref_javascript_doc_path . '/' . a:query), "\n")
    endif

    " 改行とタブを削除 {{{2
    let body = join(map(split(body, '\ze</\?pre[> ]'),
      \ 'v:val =~ "^<pre"
      \     ? "\n" .  substitute(v:val, ''^\|\n\zs'', "    ", "g") . "\n"
      \     : substitute(v:val, ''[\n\r\t]'', "", "g")'),
      \ '')

    " 不要な部分を削除 {{{2
    let body = substitute(body, '<div class="entry-content">.\{-}</div>', '', 'g')

    " <div>, <h1> - <h6>, <li>, <p>タグを改行に変換 {{{2
    let body = substitute(body,
      \ '<\%(div\|/\?h[1-6]\|/\?li\|/\?p\)\%(\s[^>]*\)\?>', '\n', 'g')

    " <code>タグを置換 {{{2
    let body = substitute(body, '<code[^>]*>\(.\{-}\)</code>', '`\1`', 'g')

    " <var>タグを置換 {{{2
    let body = substitute(body,
      \ '\n\zs<var[^>]*>\s*\(.\{-}\)\s*</var>\s*', '\*\1\* ', 'g')
    let body = substitute(body, '<var[^>]*>\s*\(.\{-}\)\s*</var>', '*\1*', 'g')

    " <noscript>タグと中身を削除 {{{2
    let body = substitute(body, '<noscript>.\{-}</noscript>', '', 'g')

    " すべてのタグを削除 {{{2
    let body = substitute(body, '<[^>]*>', '', 'g')

    " 文字参照を置換 {{{2
    let body = refsrc#replaceHtmlEntities(body)

    " 空行を詰める {{{2
    let body = substitute(body, '\r', '', 'g')
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
