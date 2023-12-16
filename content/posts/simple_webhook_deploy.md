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

また有効期限として日時をリクエストの body に含めることで、署名を可変にしました。

```golang
package main

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"os/exec"
	"strconv"
	"time"
)

var secret []byte

func init() {
	secretKey := os.Getenv("WEBHOOK_SECRET")
	if secretKey == "" {
		log.Fatal("WEBHOOK_SECRET environment variable not set")
	}
	secret = []byte(secretKey)
}

func verifySignature(message, providedSignature []byte) bool {
	mac := hmac.New(sha256.New, secret)
	mac.Write(message)
	expectedMAC := mac.Sum(nil)
	expectedSignature := fmt.Sprintf("sha256=%x", expectedMAC)
	return hmac.Equal([]byte(expectedSignature), providedSignature)
}

func handleWebhook(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		log.Println("Invalid method")
		http.Error(w, "Invalid method", http.StatusMethodNotAllowed)
		return
	}

	signature := r.Header.Get("X-Hub-Signature-256")
	body, err := io.ReadAll(r.Body)
	if err != nil {
		log.Println("Error reading body")
		http.Error(w, "Error reading body", http.StatusInternalServerError)
		return
	}
	var jsonData map[string]interface{}
	if err := json.Unmarshal(body, &jsonData); err != nil {
		log.Println("Error parsing body")
		http.Error(w, "Error parsing body", http.StatusBadRequest)
		return
	}

	if timestampStr, ok := jsonData["timestamp"].(string); ok {
		if timestamp, err := strconv.ParseInt(timestampStr, 10, 64); err == nil {
			t := time.Unix(timestamp, 0)
			if time.Since(t) > 5*time.Minute {
				log.Printf("Signature expired: %s", t.Format(time.RFC3339))
				http.Error(w, "Signature expired", http.StatusUnauthorized)
				return
			}
		} else {
			log.Println("Invalid timestamp format")
			http.Error(w, "Invalid timestamp format", http.StatusBadRequest)
			return
		}
	} else {
		log.Println("Timestamp missing")
		http.Error(w, "Timestamp missing", http.StatusBadRequest)
		return
	}

	if !verifySignature(body, []byte(signature)) {
		log.Println("Invalid signature")
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
  trigger:
    runs-on: ubuntu-latest
    steps:
      - name: Trigger Webhook
        env:
          WEBHOOK_SECRET: ${{ secrets.WEBHOOK_SECRET }}
          WEBHOOK_URL: ${{ secrets.WEBHOOK_URL }}
        run: |
          TIMESTAMP=$(date +%s)
          DATA='{"ref": "refs/heads/main", "timestamp": "'$TIMESTAMP'"}'
          SIGNATURE=$(echo -n $DATA | openssl dgst -sha256 -hmac $WEBHOOK_SECRET | sed 's/^.* //')
          curl -X POST \
          -H "Content-Type: application/json" \
          -H "X-Hub-Signature-256: sha256=$SIGNATURE" \
          -d "$DATA" \
          --fail \
          $WEBHOOK_URL
```

### サービスファイル作成

常時起動させておくために systemd のユニットファイルを作成しました。
/etc/systemd/system/deploy-app.service に以下を設定しました。

```service
[Unit]
Description=Deploy Webhook

[Service]
WorkingDirectory=/home/edge2992/deploy/github-deploy-webhook
EnvironmentFile=/home/edge2992/deploy/github-deploy-webhook/env.sh

ExecStart=/home/edge2992/deploy/github-deploy-webhook/deploy-app
Restart=always
RestartSec=5

User=edge2992
Group=edge2992
Environment=PATH=/usr/bin:/usr/local/bin

[Install]
WantedBy=multi-user.target
```

## まとめ

簡単な webhook の受け口となるアプリケーションを作成しました。
レポジトリは[こちら](https://github.com/edge2992/github-deploy-webhook)です。
service ファイルなどで常時起動させておきましょう。

実はこんなことをしなくても[adnanh/webhook](https://github.com/adnanh/webhook)という go 製の OSS があるそうです。
こちらは今度使ってみたいです。
