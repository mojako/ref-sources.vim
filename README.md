ref-sources.vim
===============

[vim-ref][git:vim-ref] 用の追加ソース。

[ref-alc.vim][git:ref-alc.vim] と同じく、データの取得に curl
(もしくは、[webapi-vim][git:webapi-vim]) を使い、HTML を整形・表示します。

[git:vim-ref]:      https://github.com/thinca/vim-ref
[git:ref-alc.vim]:  https://github.com/mojako/ref-alc.vim
[git:webapi-vim]:   https://github.com/mattn/webapi-vim

必要環境
--------

* [vim-ref][git:vim-ref]
* curl

以下は、お好みで

* [webapi-vim][git:webapi-vim]

収録ソース
----------

* cpan ([CPAN](http://search.cpan.org/))
* jquery ([jQAPI](http://jqapi.com/), 実験的)
* kotobank ([コトバンク](http://kotobank.jp/))
* kotobankej ([コトバンク 英和・和英検索](http://kotobank.jp/))

設定
----

オプションの一部を紹介します。お好みに合わせて、`~/.vimrc`
に追加してください。

その他のオプションを確認するには、各ソースのヘルプを参照
してください。

### ローカルに保存されたドキュメントを参照する (jquery)

[jQAPI](http://jqapi.com/) から HTML Version をダウンロードし、
解凍先のディレクトリを、以下のように設定してください。

```vim
let g:ref_jquery_doc_path = 'path/to/jqapi-latest'
```

### 自動リサイズ機能を有効にする (kotobank, kotobankej)

結果に合わせて、開かれるウインドウの縦サイズを調節します。

```vim
let g:ref_kotobank_auto_resize = 1
let g:ref_kotobankej_auto_resize = 1
```

もしくは、共通オプションを利用して以下の方法でも設定できます。

```vim
let g:ref_auto_resize = 1
```

### キャッシュを有効にする

```vim
let g:ref_cpan_use_cache = 1
let g:ref_jquery_use_cache = 1
let g:ref_kotobank_use_cache = 1
let g:ref_kotobankej_use_cache = 1
```

もしくは、共通オプションを利用して以下のように書きます。

```vim
let g:ref_use_cache = 1
```

TODO
----

* [cpan] Perlコードの構文強調がおかしい問題の修正
* [kotobankej] 大量の外字画像をすべて変換できるようにする
* 収録ソースをもっと増やす
