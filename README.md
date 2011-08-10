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

* kotobank ([コトバンク](http://kotobank.jp/))
* kotobankej ([コトバンク 英和・和英検索](http://kotobank.jp/))

設定
----

お好みに合わせて、`~/.vimrc` などに追加してください。

### 自動リサイズ機能を有効にする

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
let g:ref_kotobank_use_cache = 1
let g:ref_kotobankej_use_cache = 1
```

### webapi-vim を使用しない

webapi-vim をインストールしていない場合は、自動で `0`
に設定されるので、わざわざ設定する必要はありません。

```vim
let g:ref_kotobank_use_webapi = 0
let g:ref_kotobankej_use_webapi = 0
```

TODO
----

* 共通の設定オプションをまとめて設定できるようにする(ようにならないかな)
* [kotobankej] 大量の外字画像をすべて変換できるようにする
* 収録ソースをもっと増やす
