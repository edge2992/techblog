# edge2992's techblog

[![Netlify Status](https://api.netlify.com/api/v1/badges/f5f8a0db-51bd-4947-9c3a-5a614ea9b98c/deploy-status)](https://app.netlify.com/sites/enchanting-lebkuchen-5ebbf6/deploys)

テックブログです。

## セットアップ

新しいマシンでの環境構築手順は [docs/setup.md](docs/setup.md) を参照。

## HOW TO

### 記事作成

```sh
hugo new posts/<FILE_NAME>.md
```

### ビルド・プレビュー

```sh
hugo server
```

### OGP画像を作成する

```sh
sh ./makeogp.sh ./content/posts/<FILE_NAME>.md
```

`static/img/og/<FILE_NAME>.png` が生成される。front matter を書き終えてから実行すること。
