" ============================================================================
" File:         autoload/ref/cpan.vim
" Author:       mojako <moja.ojj@gmail.com>
" URL:          https://github.com/mojako/ref-sources.vim
" Last Change:  2011-09-10
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

if !exists('g:ref_cpan_use_cache') && !exists('g:ref_use_cache')
    let g:ref_cpan_use_cache = 0
endif

if !exists('g:ref_cpan_use_webapi') && !exists('g:ref_use_webapi')
    let g:ref_cpan_use_webapi = globpath(&rtp, 'autoload/http.vim') != ''
endif
"}}}

let s:source = {'name': 'cpan', 'version': 101}

" s:source.available() {{{1
" ====================
function! s:source.available()
    return executable('curl')
endfunction

" s:source.call( <query> ) {{{1
" ========================
function! s:source.call(query)
    " Webページを取得 {{{2
    let url = 'http://cpansearch.perl.org/src/' . a:query
    let ret = s:get_url(url)

    " 埋め込まれたPOD部分を抽出 {{{2
    let ret = substitute(ret, '^.\{-}\ze\n=', '', '')
    let ret = substitute(ret, '\n=cut.\{-}\ze\n=', '', 'g')
    let ret = substitute(ret, '\n=cut.\{-}$', '', '')

    " パラグラフ要素を置換 {{{2
    let ret = substitute(ret, '\n\zs=head1\s\+\(.\{-}\)\ze\n', '# \1', 'g')
    let ret = substitute(ret, '\n\zs=head2\s\+\(.\{-}\)\ze\n', '## \1', 'g')

    let ret = substitute(ret, '\n=over\%( \d\+\)\?\n', '', 'g')
    let ret = substitute(ret, '\n=back\n', '', 'g')
    let ret = substitute(ret, '\n\zs=item ', '  ', 'g')

    " ブロック要素を置換 {{{2
    let ret = substitute(ret, 'B<<\(.\{-}\)>>', '**\1**', 'g')
    let ret = substitute(ret, 'B<\(.\{-}\)>', '**\1**', 'g')
    let ret = substitute(ret, 'I<<\(.\{-}\)>>', '*\1*', 'g')
    let ret = substitute(ret, 'I<\(.\{-}\)>', '*\1*', 'g')
    let ret = substitute(ret, 'C<< \(.\{-}\) >>', '`\1`', 'g')
    let ret = substitute(ret, 'C<\(.\{-}\)>', '`\1`', 'g')

    let ret = substitute(ret, '[FLSX]<\(.\{-}\)>', '\1', 'g')

    " 文字参照を置換 {{{2
    let ret = substitute(ret, 'E<#\(\d\+\)>', '\=nr2char(submatch(1))', 'g')
    let ret = substitute(ret, 'E<#x\(\x\+\)>',
      \ '\=nr2char("0x" . submatch(1))', 'g')

    let ret = substitute(ret, 'E<gt>', '>', 'g')
    let ret = substitute(ret, 'E<lt>', '<', 'g')
    "}}}2

    return ret
endfunction

" s:source.complete( <query> ) {{{1
" ============================
function! s:source.complete(query)
    return self.search(a:query)
endfunction

" s:source.get_body( <query> ) {{{1
" ============================
function! s:source.get_body(query)
    " <query>と一致するインデックスが見付かった場合、そのページを返す {{{2
    let idx = self.index(a:query)
    if idx != ''
        return s:iconv(s:get_option('use_cache')
          \ ? self.cache(idx, self) : self.call(idx), 'utf-8', &enc)
    endif

    " <query>を検索 {{{2
    let result = self.search(a:query)

    " 検索結果が1件の場合、そのページを返す {{{2
    if len(result) == 1
        return {
          \ 'body': s:iconv(s:get_option('use_cache')
          \     ? self.cache(self._index[result[0]], self)
          \     : self.call(self._index[result[0]]), 'utf-8', &enc),
          \ 'query': result[0]
          \ }
    endif

    " 検索結果に<query>と一致するものがある場合、そのページを返す {{{2
    let idx = index(result, a:query, 0, 1)
    if idx >= 0
        return {
          \ 'body': s:iconv(s:get_option('use_cache')
          \     ? self.cache(self._index[result[idx]], self)
          \     : self.call(self._index[result[idx]]), 'utf-8', &enc),
          \ 'query': result[idx]
          \ }
    endif

    " それ以外の場合、検索結果のリストを返す {{{2
    return {'body': result, 'query': a:query . '?'}
    "}}}2
endfunction

" s:source.get_keyword() {{{1
" ======================
function! s:source.get_keyword()
    let isk_save = &l:isk
    setlocal isk=48-58,65-90,97-122
    let kwd = expand('<cword>')
    let &l:isk = isk_save
    return kwd
endfunction

" s:source.index( [ <query> ] ) {{{1
" =============================
function! s:source.index(...)
    " インデックスが存在しない場合、キャッシュからロードする {{{2
    if !exists('self._index')
        let self._index = s:get_option('use_cache')
          \ ? s:list2dict(self.cache('_index', [])) : {}
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

" s:source.search( <query> ) {{{1
" ==========================
function! s:source.search(query)
    " インデックスの初期化 {{{2
    call self.index()

    " 検索結果のWebページを取得 {{{2
    let url = 'http://search.cpan.org/search?m=module&q='
      \ . s:encodeURIComponent(a:query)
      \ . '&n=' . g:ref_cpan_search_page_size
    let html = s:get_url(url)

    " 検索結果をインデックスに追加 {{{2
    let ret = []
    for item in split(html, '<!--item-->')[1:]
        let name = matchstr(item, '<b>\zs.\{-}\ze</b>')
        let link = matchstr(item, '<a href="\zs.\{-}\.\%(pm\|pod\)\ze">')
        if link != ''
            let self._index[name] = substitute(link, '^/\~\([^/]\+\)',
              \ '\=toupper(submatch(1))', '')
            call add(ret, name)
        endif
    endfor

    " インデックスをキャッシュ {{{2
    if s:get_option('use_cache')
        call self.cache('_index', s:dict2list(self._index), 1)
    endif

    " 検索結果のリストを返す {{{2
    return ret
    "}}}2
endfunction
"}}}1

function! ref#cpan#define()
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
  \ && ref#cache(s:source.name, '_version', [0])[0] < 101
    call ref#rmcache(s:source.name)
    call ref#cache(s:source.name, '_version', [s:source.version])
endif

" s:cpo_save {{{1
let &cpo = s:cpo_save
unlet s:cpo_save
"}}}

" vim: set et sts=4 sw=4 wrap:
