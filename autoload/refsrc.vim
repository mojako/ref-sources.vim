" ============================================================================
" File:         autoload/refsrc.vim
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
if !exists('g:ref_use_webapi')
    let g:ref_use_webapi = (globpath(&rtp, 'autoload/http.vim') != '')
endif
"}}}

" HTML entities {{{1
let s:html_entities = {
  \ 'amp'   : '&',
  \ 'lt'    : '<',  'gt'    : '>',
  \ 'quot'  : '"',  'apos'  : "'",
  \ 'lsquo' : '‘', 'rsquo' : '’',
  \ 'ldquo' : '“', 'rdquo' : '”',
  \ 'nbsp'  : '　',
  \ 'ndash' : '-',  'mdash' : '—',
  \ 'theta' : 'θ',
  \ 'Agrave': 'À',  'Aacute': 'Á',  'AElig' : 'Æ',
  \ 'Egrave': 'È',  'Eacute': 'É',
  \ 'Igrave': 'Ì',  'Iacute': 'Í',
  \ 'Ograve': 'Ò',  'Oacute': 'Ó',  'OElig' : 'Œ', 'Oslash': 'Ø',
  \ 'Ugrave': 'Ù',  'Uacute': 'Ú',
  \ 'agrave': 'à', 'aacute': 'á', 'aelig' : 'æ',
  \ 'egrave': 'è', 'eacute': 'é',
  \ 'igrave': 'ì', 'iacute': 'í',
  \ 'ograve': 'ò', 'oacute': 'ó', 'oelig' : 'œ', 'oslash': 'ø',
  \ 'ugrave': 'ù', 'uacute': 'ú',
  \ 'Ccedil': 'Ç',  'ccedil': 'ç',
  \ 'szlig' : 'ß',
  \ 'eth'   : 'ð',
  \ 'copy'  : '©',  'reg'   : '®', 'trade' : '™',
  \ 'dagger': '†', 'Dagger': '‡',
  \ }
"}}}

" refsrc#autoResizeRefWindow( <min_size> ) {{{1
" ========================================
function! refsrc#autoResizeRefWindow(min)
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
        let h += 1 + strdisplaywidth(line) / w
        let i += 1
    endwhile
    if h < a:min
        let h = a:min
    elseif h > w:old_height
        let h = w:old_height
    endif
    exe 'resize' h

    augroup RestoreRefWindowSize
        autocmd! FileType <buffer> if exists('w:old_height') |
          \     exe 'resize' w:old_height |
          \     unlet w:old_height |
          \     augroup! RestoreRefWindowSize |
          \ endif
    augroup END
endfunction

" refsrc#encodeURIComponent( <string> ) {{{1
" =====================================
function! refsrc#encodeURIComponent(str)
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
        let i += 1
    endwhile
    return ret
endfunction

" refsrc#decodeURIComponent( <string> ) {{{1
" =====================================
function! refsrc#decodeURIComponent(str)
    let ret = ''
    let str = a:str
    while 1
        let m = matchlist(str, '.\{-}\ze\(\%(%\x\x\)\+\)\(.*\)')
        if empty(m)
            let ret .= str
            return ret
        endif
        let ret .= m[0]
        let s = split(m[1], '%')
        let len = len(s)
        let i = 0
        while i < len
            let n = str2nr(s[i], 16)
            if n <= 0x7F
                let ret .= nr2char(n)
                let i += 1
            elseif n <= 0xBF
                let i += 1
            elseif n <= 0xDF
                let ret .= nr2char((n - 192) * 64
                  \ + (str2nr(s[i+1], 16) - 128))
                let i += 2
            elseif n <= 0xEF
                let ret .= nr2char((n - 224) * 4096
                  \ + (str2nr(s[i+1], 16) - 128) * 64
                  \ + (str2nr(s[i+2], 16) - 128))
                let i += 3
            elseif n <= 0xF7
                let ret .= nr2char((n - 240) * 262144
                  \ + (str2nr(s[i+1], 16) - 128) * 4096
                  \ + (str2nr(s[i+2], 16) - 128) * 64
                  \ + (str2nr(s[i+3], 16) - 128))
                let i += 4
            else
                let i += 1
            endif
        endwhile
        let str = m[2]
    endwhile
endfunction

" refsrc#get_url( <url>, [ <data> ] ) {{{1
" ===================================
function! refsrc#get_url(url, ...)
    if a:0
        if type(a:1) == type({})
            let data = []
            for [key, value] in items(a:1)
                call add(data, key . '=' . refsrc#encodeURIComponent(value))
            endfor
            let url = a:url . '?' . join(data, '&')
        else
            let url = a:url . '?' . a:1
        endif
    else
        let url = a:url
    endif

    if g:ref_use_webapi
        return http#get(url).content
    else
        return ref#system(['curl', '-kLs', url]).stdout
    endif
endfunction

" refsrc#iconv( <expr>, <from>, <to> ) {{{1
" ====================================
function! refsrc#iconv(expr, from, to)
    if a:from == '' || a:to == '' || a:from ==? a:to
        return a:expr
    elseif type(a:expr) == type([]) || type(a:expr) == type({})
        return map(a:expr, 'refsrc#iconv(v:val, a:from, a:to)')
    endif

    let ret = iconv(a:expr, a:from, a:to)
    return ret != '' ? ret : a:expr
endfunction

" refsrc#replaceHtmlEntities( <html> ) {{{1
" ====================================
function! refsrc#replaceHtmlEntities(html)
    let html = substitute(a:html, '&#x\(\x\+\);',
      \ '\=nr2char("0x" . submatch(1))', 'g')
    let html = substitute(html, '&#\(\d\+\);', '\=nr2char(submatch(1))', 'g')
    let html = substitute(html, '&\(\a\{-}\);',
      \ '\=get(s:html_entities, submatch(1), submatch(0))', 'g')

    return html
endfunction
"}}}

" s:cpo_save {{{1
let &cpo = s:cpo_save
unlet s:cpo_save
"}}}

" vim: set et sts=4 sw=4 wrap:
