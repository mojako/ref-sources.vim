ref-sources.vim
===============

[vim-ref][git:vim-ref] 用の追加ソース。

[ref-alc.vim][git:ref-alc.vim] と同じく、データの取得に curl
(もしくは、[webapi-vim][git:webapi-vim]) を使い、HTML を整形・表示します。

- 2011-08-14: CPAN を追加

つくってから、perldoc がある事に気付いた。

- 2011-08-12: jquery を追加

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

お好みに合わせて、`~/.vimrc` などに追加してください。

### ローカルに保存されたドキュメントを参照する (jquery)

[jQAPI](http://jqapi.com/) から HTML Version をダウンロードし、
解凍先のディレクトリを、以下のように設定してください。

```vim
let g:ref_jquery_doc_path = 'path/to/jqapi-latest'
```

このオプションを設定すると、ページのロードは高速化できますが、
初回検索時のもたつきは改善されません。

これは、初回検索時にインデックスを作成している為で、これを
高速化するには、キャッシュを有効にしてください。

なお、キャッシュ・データはローカル / オンライン共通なので、
途中でこのオプションを切り替えても問題ありません。

### 自動リサイズ機能を有効にする (kotobank, kotobankej)

結果に合わせて、開かれるウインドウの縦サイズを調節します。

`g:ref_<source_name>_auto_resize_min_size` の値 (default: 10)
以下に縮小される事はありません。

注意!: ウインドウを閉じずに他のソースを表示すると、
縮小されたままになります。

```vim
let g:ref_kotobank_auto_resize = 1
let g:ref_kotobankej_auto_resize = 1
```

### キャッシュを有効にする

```vim
let g:ref_cpan_use_cache = 1
let g:ref_jquery_use_cache = 1
let g:ref_kotobank_use_cache = 1
let g:ref_kotobankej_use_cache = 1
```

### webapi-vim を使用しない (共通設定)

webapi-vim をインストールしていない場合は、自動で `0`
に設定されるので、わざわざ設定する必要はありません。

```vim
let g:ref_use_webapi = 0
```

TODO
----

* doc ファイルの作成
* 共通の設定オプションをまとめて設定できるようにする
* [kotobankej] 大量の外字画像をすべて変換できるようにする
* 収録ソースをもっと増やす
