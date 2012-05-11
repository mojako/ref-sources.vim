ref-sources.vim
===============

[vim-ref][git:vim-ref] 用の追加ソース・パッケージ。

[vim-ref][git:vim-ref] 付属の ref-alc などとは違い、
テキストベースなブラウザを使わず、curl を使用します。

[git:vim-ref]:          https://github.com/thinca/vim-ref
[git:webapi-vim]:       https://github.com/mattn/webapi-vim
[git:open-browser.vim]: https://github.com/tyru/open-browser.vim

必要環境
--------

* [vim-ref][git:vim-ref]
* curl

以下は、お好みで

* [webapi-vim][git:webapi-vim]
* [open-browser.vim][git:open-browser.vim]

収録ソース
----------

* cpan ([CPAN](http://search.cpan.org/))
* jquery ([jQAPI](http://jqapi.com/), 実験的)
* javascript ([JSRef](http://jsref.64p.org/), 実験的)
* kotobank ([コトバンク](http://kotobank.jp/))
* kotobankej ([コトバンク 英和・和英検索](http://kotobank.jp/))
* wikipedia ([ウィキペディア](http://www.wikipedia.org/), 実験的)

設定
----

オプションの一部を紹介します。お好みに合わせて、`~/.vimrc`
に追加してください。

その他のオプションを確認するには、各ソースのヘルプを参照
してください。

### ローカルに保存されたドキュメントを参照する (jquery, javascript)

[jQAPI](http://jqapi.com/) から HTML Version をダウンロードして解凍、
[JSRefのGitリポジトリ](https://github.com/tokuhirom/jsref)をCloneし、
ディレクトリを、以下のように設定してください。

```vim
let g:ref_jquery_doc_path = 'path/to/jqapi-latest'
let g:ref_javascript_doc_path = 'path/to/jsref/htdoc'
```

### 自動リサイズ機能を有効にする (kotobank, kotobankej)

結果に合わせて、開かれるウインドウの縦サイズを調節します。

```vim
let g:ref_kotobank_auto_resize = 1
let g:ref_kotobankej_auto_resize = 1
```

もしくは、共通オプションを利用して以下の方法 でも設定できます。

```vim
let g:ref_auto_resize = 1
```

### 各言語版のウィキペディアで検索する

`g:ref_wikipedia_lang` に使用したい言語を設定します。

```vim
let g:ref_wikipedia_lang = 'en'
```

以下のようにすると、`wikipedia` に加え、英語版で検索する為の
`wikipedia_en` が登録されます。

```vim
let g:ref_wikipedia_lang = ['ja', 'en']
```

もしくは、辞書型で設定する事で自由にソース名を付けられます。

```vim
let g:ref_wikipedia_lang = {'wikij': 'ja', 'wikie': 'en'}
```

### キャッシュを有効にする

```vim
let g:ref_cpan_use_cache = 1
let g:ref_jquery_use_cache = 1
let g:ref_javascript_use_cache = 1
let g:ref_kotobank_use_cache = 1
let g:ref_kotobankej_use_cache = 1
```

もしくは、共通オプションを利用して以下のように書きます。

```vim
let g:ref_use_cache = 1
```

TODO
----

* [cpan] サンプルコードの構文強調がおかしくなる問題の修正
* [kotobankej] 大量の外字画像をすべて変換できるようにする
* [wikipedia] キャッシュ機能を追加
* 共通の関数をモジュール化
* 収録ソースをもっと増やす
