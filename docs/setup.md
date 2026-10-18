# 開発環境セットアップ

新しいマシンでこのブログを書き始めるための手順。macOS (Apple Silicon) を前提に書いているが、
Linux でも Homebrew / Go の入れ方以外は同じ。

## 必要なもの

| ツール | 用途 | 備考 |
| --- | --- | --- |
| Hugo (extended) | サイトのビルド・プレビュー | テーマが SCSS を使うので **extended 版が必須** |
| Go | tcardgen のインストール | Go 1.21 以降 |
| tcardgen | OGP 画像の生成 | `go install` で入れる |
| git | リポジトリ・テーマの submodule 取得 | |

## 1. リポジトリを取得する

テーマ (`themes/noteworthy`) は git submodule なので、`--recursive` を忘れないこと。
忘れた場合はビルドが `module "noteworthy" not found` で失敗する。

```sh
git clone --recursive https://github.com/edge2992/techblog.git
cd techblog

# clone 済みで submodule が空の場合
git submodule update --init --recursive
```

## 2. Hugo をインストールする

```sh
brew install hugo
```

`hugo version` の出力に `+extended` が含まれていることを確認する。

```sh
$ hugo version
hugo v0.164.0+extended+withdeploy darwin/arm64 ...
```

> **バージョンについて**
> Netlify 側は `netlify.toml` の `HUGO_VERSION` (現在 0.142.0) で固定されている。
> テーマの `theme.toml` の `min_version` も 0.142.0。
> ローカルは Homebrew の最新版で問題なくビルドできているが、ローカルだけビルドが通って
> Netlify で落ちる場合はこのバージョン差を疑う。厳密に揃えたいときは
> [Hugo の releases](https://github.com/gohugoio/hugo/releases) から
> `hugo_extended_0.142.0_darwin-universal.tar.gz` を落として PATH に置く。

## 3. Go と tcardgen をインストールする

```sh
brew install go
go install github.com/Ladicle/tcardgen@latest
```

`go install` したバイナリは `$(go env GOPATH)/bin` (デフォルトは `~/go/bin`) に入る。
PATH に通っていなければ shell の rc に追記する。

```sh
# ~/.zshrc
export PATH="$PATH:$(go env GOPATH)/bin"
```

確認:

```sh
which tcardgen   # => /Users/<you>/go/bin/tcardgen
```

## 4. 動作確認

### ビルド

```sh
hugo --gc --minify
```

`languageCode` 関連の deprecation WARN が出るが、ビルド自体は成功する（Hugo 0.158 以降の警告）。

### プレビュー

```sh
hugo server
```

http://localhost:1313 が開けば OK。

### OGP 画像の生成

```sh
sh ./makeogp.sh ./content/posts/<FILE_NAME>.md
```

`static/img/og/<FILE_NAME>.png` が出力される。
記事の front matter の `title` / `categories` / `tags` / `date` が画像に焼き込まれるので、
**front matter を書き終えてから実行する**こと。

生成物をリポジトリに入れたくない試し打ちのときは、tcardgen を直接叩いて出力先を変える。

```sh
tcardgen \
  --fontDir ./assets/fonts/kinto-sans \
  --output /tmp/ogtest \
  --template ./static/ogp/ogp_template.png \
  --config ./tcardgen.yaml \
  ./content/posts/<FILE_NAME>.md
```

## 記事を書くときの流れ

```sh
hugo new posts/<FILE_NAME>.md   # 記事の雛形を作る
hugo server                     # 書きながらプレビュー
sh ./makeogp.sh ./content/posts/<FILE_NAME>.md   # 書き終わったら OGP を生成
```

## つまずきポイント

- **`module "noteworthy" not found`** — submodule が未取得。`git submodule update --init --recursive`。
- **SCSS 関連のエラー / スタイルが当たらない** — Hugo が extended 版でない。`hugo version` に `+extended` があるか確認。
- **`tcardgen: command not found`** — `~/go/bin` が PATH にない。
- **`open ./static/fonts/kinto/Kinto Sans: no such file or directory`** — 古い手順の名残。
  現在フォントは `assets/fonts/kinto-sans/` にリポジトリ内で管理されており、`makeogp.sh` が
  そこを参照する。`static/fonts/` は不要（`.gitignore` にも入っている）。

## 関連ファイル

- `config.toml` — Hugo のサイト設定（メニュー、ソーシャルリンク等）
- `netlify.toml` — Netlify のビルド設定と Hugo バージョン
- `tcardgen.yaml` — OGP 画像の文字配置・色・フォントサイズ
- `makeogp.sh` — OGP 生成のラッパースクリプト
- `assets/fonts/kinto-sans/` — OGP 画像用の Kinto Sans フォント
- `static/ogp/ogp_template.png` — OGP 画像の背景テンプレート
