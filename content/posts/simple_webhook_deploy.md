---
title: "シンプルなWebhookサーバーでGitHub Actionsからローカル環境にデプロイする"
author: ["えじっさ"]
date: 2023-12-10T18:16:00+09:00
tags: ["network", "golang"]
images:
  - "img/og/simple_webhook_deploy.png"
categories: ["network"]
draft: false
---

こんにちは。
私は日記を Markdown で書いて GitHub に保存しています。
プライベートなことも書くので、ローカル環境内で立てているサーバーでローカル向けに配信しておこうと思いました。
簡単な webhook 用のサーバーを実装して、webhook の通知が来たときに任意のデプロイスクリプトを実行するようにすれば、簡単にデプロイできそうです。
webhook は GitHub Action によって、main の更新をトリガーとします。
インターネットに向けて webhook を公開する方法は cloudflared tunnel を使いました。
詳しくは、[Cloudflared の CLI を利用してローカル環境の WEB サービスを公開する](../cloudflared_publish/)を見てみてください。

## Webhook サーバー実装

実装は以下です。go で書きました。
verifySignature で署名を確認します。
[HMAC-SHA256](https://www.okta.com/jp/identity-101/hmac/)を使いました。

```golang
package main

import (
	"crypto/hmac"
	"crypto/sha256"
	"fmt"
	"io"
	"log"
	"net/http"
	"os/exec"
)

var secret = []byte("<secret-key-here>")

func varifySignature(message, providedSignature []byte) bool {
	mac := hmac.New(sha256.New, secret)
	mac.Write(message)
	expectedMAC := mac.Sum(nil)
	expectedSignature := fmt.Sprintf("sha256=%x", expectedMAC)
	return hmac.Equal([]byte(expectedSignature), providedSignature)
}

func handleWebhook(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Invalid method", http.StatusMethodNotAllowed)
		return
	}

	signature := r.Header.Get("X-Hub-Signature-256")
	body, err := io.ReadAll(r.Body)
	if err != nil {
		http.Error(w, "Error reading body", http.StatusInternalServerError)
		return
	}

	if !varifySignature(body, []byte(signature)) {
		http.Error(w, "Invalid signature", http.StatusForbidden)
		return
	}

	fmt.Printf("Received webhook: %s\n", string(body))

	cmd := exec.Command("/bin/bash", "./deploy.sh")
	err = cmd.Run()
	if err != nil {
		log.Printf("Deployment script failed: %s", err)
		http.Error(w, "Deployment script failed", http.StatusInternalServerError)
		return
	}
	log.Println("Deployment script succeeded")
	w.WriteHeader(http.StatusOK)
	w.Write([]byte("Deployment script succeeded"))
}

func main() {
	http.HandleFunc("/webhook", handleWebhook)
	log.Fatal(http.ListenAndServe(":8080", nil))
}

```

## GitHub Actions 設定

以下のようにしました。.github/actions/deploy-webhook.yml に書いています。
main が更新される度に webhook を送信します。
secrets に WEBHOOK_SECRET と WEBHOOK_URL を設定する必要があります。

```yaml
name: Deploy Webhook

on:
  push:
    branches:
      - main

jobs:
  webhook:
    runs-on: ubuntu-latest
    steps:
      - name: Trigger Webhook
        run: |
          curl -X POST -H "Content-Type: application/json" -H "X-Hub-Signature-256: sha256=$(echo -n ${{ secrets.WEBHOOK_SECRET }})" -d '{"ref": "refs/heads/main"}' --fail ${{ secrets.WEBHOOK_URL }}
```

### WEBHOOK_SECRET 作成

WEBHOOK_SECRET は署名するデータと秘密鍵で作成する必要します。以下スクリプトで作成してください。

```bash
#!/bin/bash

# 秘密鍵を設定します（この値は実際の秘密鍵に置き換えてください）
SECRET_KEY="<your-secret-key-here"

# 署名するデータ（この例ではJSONデータ）
DATA='{"ref": "refs/heads/main"}'

# HMAC SHA256署名を計算します
SIGNATURE=$(echo -n "$DATA" | openssl dgst -sha256 -hmac "$SECRET_KEY" | sed 's/^.* //')

echo $SIGNATURE
```

## まとめ

簡単な webhook の受け口となるアプリケーションを作成しました。
service ファイルなどで常時起動させておきましょう。

実はこんなことをしなくても[adnanh/webhook](https://github.com/adnanh/webhook)という go 製の OSS があるそうです。
こちらは今度使ってみたいです。
