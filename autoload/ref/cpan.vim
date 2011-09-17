" ============================================================================
" File:         autoload/ref/cpan.vim
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
if !exists('g:ref_cpan_search_page_size')
    let g:ref_cpan_search_page_size = 20
endif

if !exists('g:ref_cpan_use_cache')
    let g:ref_cpan_use_cache = exists('g:ref_use_cache') ? g:ref_use_cache : 0
endif
"}}}

let s:source = {'name': 'cpan', '_index': {}}

" s:source.available() {{{1
" ====================
function! s:source.available()
    return executable('curl')
endfunction

" s:source.complete( <query> ) {{{1
" ============================
function! s:source.complete(query)
    return self.search(a:query)
endfunction

" s:source.get_body( <query> ) {{{1
" ============================
function! s:source.get_body(query)
    " <query>のキャッシュが存在する場合、それを返す {{{2
    if g:ref_cpan_use_cache
        let cache_name = substitute(toupper(a:query), ':\+', '_', 'g')
        let cache = self.cache(cache_name)
        if type(cache) == type([])
            return {
              \ 'query' : cache[0],
              \ 'body'  : cache[1:],
              \ }
        endif
    endif

    " インデックスから<query>の項目を探す {{{2
    let m = filter(keys(self._index), 'v:val =~? ''^'' . a:query . ''$''')
    if len(m)
        let query = m[0]
    " 見付からない場合、CPANから<query>を検索する {{{2
    else
        let s = self.search(a:query)
        let m = filter(copy(s), 'v:val =~? ''^'' . a:query . ''$''')
        if len(m)
            let query = m[0]
        elseif len(s) == 1
            let query = s[0]
        else
            " 候補が複数ある場合は、リストを返す
            return {
              \ 'query' : a:query . '?',
              \ 'body'  : s,
              \ }
        endif
    endif

    " キャッシュが有効な場合の処理 {{{2
    if g:ref_cpan_use_cache
        " 候補のキャッシュが存在する場合、それを返す {{{3
        let cache_name = substitute(toupper(query), ':\+', '_', 'g')
        let cache = self.cache(cache_name)
        if type(cache) == type([])
            return {
              \ 'query' : cache[0],
              \ 'body'  : cache[1:],
              \ }
        endif

        " 存在しない場合、CPANからページを取得してキャッシュする {{{3
        let body = s:get_body('http://cpansearch.perl.org/src/'
          \ . self._index[query])

        call self.cache(cache_name, [query, body], 1)

        " ページを返す {{{3
        return {
          \ 'query' : query,
          \ 'body'  : body,
          \ }
        "}}}
    endif

    " キャッシュが無効な場合、CPANからページを取得して返す {{{2
    return {
      \ 'query' : query,
      \ 'body'  : s:get_body('http://cpansearch.perl.org/src/'
      \     . self._index[query]),
      \ }
    "}}}
endfunction

" s:source.get_keyword() {{{1
" ======================
function! s:source.get_keyword()
    let isk_save = &l:isk
    setlocal isk=48-58,65-90,97-122     " 0-9:A-Za-z
    let kwd = expand('<cword>')
    let &l:isk = isk_save
    return kwd
endfunction

" s:source.search( <query> ) {{{1
" ==========================
function! s:source.search(query)
    " 検索結果のWebページを取得 {{{2
    let result = refsrc#get_url('http://search.cpan.org/search', {
      \ 'm' : 'module',
      \ 'n' :  g:ref_cpan_search_page_size,
      \ 'q' :  a:query,
      \ })

    " 検索結果をインデックスに追加 {{{2
    let ret = []
    for item in split(result, '<!--item-->')[1:]
        let name = matchstr(item, '<b>\zs.\{-}\ze</b>')
        let link = matchstr(item, '<a href="\zs.\{-}\.\%(pm\|pod\)\ze">')
        if link != ''
            let self._index[name] = substitute(link, '^/\~\([^/]\+\)',
              \ '\=toupper(submatch(1))', '')
            call add(ret, name)
        endif
    endfor

    " 検索結果のリストを返す {{{2
    return ret
    "}}}
endfunction
"}}}

function! ref#cpan#define()
    return copy(s:source)
endfunction

" s:get_body( <url> ) {{{1
" ===================
function! s:get_body(url)
    " CPANからソースを取得 {{{2
    let body = substitute(refsrc#get_url(a:url), '\r\n\?', '\n', 'g')

    " 埋め込まれたPOD部分を抽出 {{{2
    let body = substitute(body, '^.\{-}\ze\n=', '', '')
    let body = substitute(body, '\n=cut.\{-}\ze\n=', '', 'g')
    let body = substitute(body, '\n=cut.\{-}$', '', '')

    " パラグラフ要素を置換 {{{2
    let body = substitute(body, '\n\zs=head1\s\+\(.\{-}\)\ze\n', '# \1', 'g')
    let body = substitute(body, '\n\zs=head2\s\+\(.\{-}\)\ze\n', '## \1', 'g')

    let body = substitute(body, '\n=over\%( \d\+\)\?\n', '', 'g')
    let body = substitute(body, '\n=back\n', '', 'g')
    let body = substitute(body, '\n\zs=item\%(\s\+\*\)\?\s*\n*', '  * ', 'g')

    " インライン要素を置換 {{{2
    let body = substitute(body, 'B<<\(.\{-}\)>>', '**\1**', 'g')
    let body = substitute(body, 'B<\(.\{-}\)>', '**\1**', 'g')
    let body = substitute(body, 'I<<\(.\{-}\)>>', '*\1*', 'g')
    let body = substitute(body, 'I<\(.\{-}\)>', '*\1*', 'g')
    let body = substitute(body, 'C<< \(.\{-}\) >>', '`\1`', 'g')
    let body = substitute(body, 'C<\(.\{-}\)>', '`\1`', 'g')

    let body = substitute(body, '[FLSX]<\(.\{-}\)>', '\1', 'g')

    " 文字参照を置換 {{{2
    let body = substitute(body, 'E<#\(\d\+\)>', '\=nr2char(submatch(1))', 'g')
    let body = substitute(body, 'E<#x\(\x\+\)>',
      \ '\=nr2char("0x" . submatch(1))', 'g')

    let body = substitute(body, 'E<gt>', '>', 'g')
    let body = substitute(body, 'E<lt>', '<', 'g')

    " 空行を詰める {{{3
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
