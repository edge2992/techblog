---
title: "ChatGPT APIでコードレビューやコミットメッセージ生成を行う"
author: ["えじっさ"]
tags: ["chatgpt", "ai"]
date: 2023-12-07T00:26:56+09:00
images:
  - "img/og/commit_code_review_chatgpt_api.png"
categories: ["tool"]
draft: false
---

2023 年を振り返ってみると生成 AI が話題でした。
私も chatGPT には 1 年弱ほどお布施をしつづけていて、最近はダイエットのためのトレーニングメニューを立ててもらったり、お酒選びに付き合ってもらったりするのに使いました。
業務でも単純なスクリプトを書いてもらったり、関数や変数の命名に困ったときにはこっそり使っています。 (プログラム自体は入力しないように気をつけながら...)

業務ではなかなか生成 AI をフル活用するわけには行きませんが、個人的に開発をするときには chatGPT や github copilot などをできるだけ活用するようにしています。
そこで本記事では、chatGPT の API を使って git のコミットメッセージを自動生成してもらう方法と プルリクエストをコードレビューをしてもらう方法を共有します。

## コミットメッセージ自動生成

git の hook を使って、コミット時に差分を入力として chatGPT API にコミットメッセージを作ってもらう方法です。
この手のツールは色々ありますが、自分が検討していた 2023 年 4 月の時点では一番 star 数が多そうだった
[di-sukharev/opencommit](https://github.com/di-sukharev/opencommit) を使っているため、そちらを紹介します。
次のようなコミットメッセージを自動生成できます。

```
feat: add LinkCollector class to scrape links from HTML content

- Added a new file `link_collector.py` in the `scraper` module to implement the `LinkCollector` class.
- The `LinkCollector` class has a constructor that takes a `base_url` parameter.
- Implemented the `fetch_links` method in the `LinkCollector` class to fetch links from the base URL.
- Implemented the `_fetch_content` method in the `LinkCollector` class to make a GET request to the base URL and return the response content.
- Implemented the `_extract_links` method in the `LinkCollector` class to extract links from the HTML content using BeautifulSoup.
- Added a new method `fetch_links_from_file` in the `LinkCollector` class to fetch links from an HTML file.
- Added necessary imports and type hints in the `link_collector.py` file.
```

### di-sukharev/opencommit の紹介

前述の通り、ChatGPT API でコミット時にメッセージを自動生成する CLI ツールです。
設定をすると次のように commit するとコミットメッセージが予め記入された状態で指定されているエディター (vi) が立ち上がります。

![commit gif](/img/codereview/auto_commit.gif)

自動生成されたコミットに不満がなければそのままエディタのメッセージを保存して終了すればいつもどおりコミットできます。

ChatGPT の入力に制限があるので、沢山のファイルを編集している場合はある程度の差分ごとに API で問い合わせてその都度 Commit の Title 生成をします。
エディタ上にはすべての出力がつながって表示されるので、私はその中から一番良さそうな commit message を選んで先頭に持ってきています。

以下は複数のファイルをまとめてコミットしたときに自動生成されたコミットメッセージです。
面倒くさいので私は他のメッセージもすべてそのまま残してしまっていますが、消すこともできます。

```
feat(App.tsx): import and add ToastContainer component from react-toastify to display toast notifications at the top-right corner of the app

feat(package.json): add react-toastify package for displaying toast notifications in the app
feat(LogDetail.tsx): remove unused errorMessage state and css, import toast from react-toastify, add toast notifications for success and error when deleting a study log
feat(useLocationChange.tsx): create a new hook useLocationChange to handle location changes in the app
feat(EditLog/index.tsx): import toast from react-toastify, add toast notifications for success and error when updating a study log
feat(NewLog/index.tsx): import toast from react-toastify, add toast notification for success when creating a new study log
```

### 設定方法

設定方法について紹介します。
おそらく API キーの取得にクレジットカードを登録しているアカウントが必要です。

1. OpenCommit をインストールする

```
npm install -g opencommit
```

2. OpenAI から API キーを取得して OpenCommit に設定する

```
oco config set OCO_OPENAI_API_KEY=<your_api_key>
```

ここで、~/.opencommit に設定ファイルが作成されています。
モデルや言語（日本語、英語など）、絵文字の使用の有無なども設定可能です。

3. レポジトリにフックを登録する

```
oco hook set
```

こちらはレポジトリごとに行う必要があります。

### 費用について

API は従量課金で、gpt-3.5-turbo では 0.002 ドル/1K tokens となっています。（token = 単語数）
1 行 80 文字で 1 単語 5 文字と仮定すると 3 万行ほどコミットすると 1 ドル請求されることになります。

私が業務時間後に遊ぶ分にはほとんど無料で使用できています。

## プルリクエストのコードレビュー

github actions を使って、プルリク作成時にコードレビューを chatGPT API に行ってもらっています。
[anc95/ChatGPT-CodeReview](https://github.com/anc95/ChatGPT-CodeReview)を使っています。
ここでは軽く紹介程度に留めさせてください。

### anc95/ChatGPT-CodeReview の紹介

chatGPT API でコードレビューをしてもらうプロジェクトです。
私の個人開発では次のように沢山コードレビューをもらっています。
右側のコメントはほどんど ChatGPT のコードレビューです。
一人で開発している寂しさが薄まるという隠れたメリットがあります。

![code-review](/img/codereview/codereview_sample.png)

実際にコードレビューされている例は次のようになります。

![code-review](/img/codereview/review_sample1.png)

### 設定方法

github action を設定します。
.github/workflows/cr.yml に次の設定を書いています。
別途 SECRET に GITHUB_TOKEN と OPENAI_API_KEY を設定する必要があります。

```yaml
name: Code Review

permissions:
  contents: read
  pull-requests: write

on:
  pull_request:
    types: [opened, reopened, synchronize]

jobs:
  test:
    # if: ${{ contains(github.event.*.labels.*.name, 'gpt review') }} # Optional; to run only when a label is attached
    runs-on: ubuntu-latest
    steps:
      - uses: anc95/ChatGPT-CodeReview@main
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          OPENAI_API_KEY: ${{ secrets.OPENAI_API_KEY }}
          # Optional
          LANGUAGE: Japanese
          OPENAI_API_ENDPOINT: https://api.openai.com/v1
          MODEL: gpt-3.5-turbo # https://platform.openai.com/docs/models
          PROMPT: # example: Please check if there are any confusions or irregularities in the following code diff:
          top_p: 1 # https://platform.openai.com/docs/api-reference/chat/create#chat/create-top_p
          temperature: 1 # https://platform.openai.com/docs/api-reference/chat/create#chat/create-temperature
          # max_tokens: 10000
          # MAX_PATCH_LENGTH: 10000 # if the patch/diff length is large than MAX_PATCH_LENGTH, will be ignored and won't review. By default, with no MAX_PATCH_LENGTH set, there is also no limit for the patch/diff length.
```

### 費用

こちらもコミットメッセージ自動生成と同様にほとんど無料でつかうことができます。

## まとめ

コードレビューとコミットメッセージの自動化について紹介しました。
git のコミットメッセージは 5 月ごろから個人開発ではほぼ全てのレポジトリで使っています。
コードレビューは gpt-3.5-turbo では少し完成度が低く、ときどき良いレビューがあるといいなという期待感でした。
gpt-4-32k など長文に対応していて性能もよいモデルがあるのでこちらにレビューさせてみればもっと良い結果が得られるでしょう。

業務では使うことは難しいですが、とても便利なのでぜひ一度使ってみてください。
