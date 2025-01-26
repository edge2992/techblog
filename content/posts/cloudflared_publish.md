---
title: "Cloudflared の CLI を利用してローカル環境の WEB サービスを公開する"
author: ["えじっさ"]
tags: ["network"]
date: 2023-12-10T11:16:21+09:00
images:
  - "img/og/cloudflared_publish.png"
categories: ["network"]
draft: false
---

cloudflare の CLI を使って WEB サービスを公開してみる。
前提条件として、CloudFlared を権威サーバーとしているドメインを所有していることが必要となる。

## cloudflared をインストールする

以下を参考にインストールする

https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/get-started/create-local-tunnel/#1-download-and-install-cloudflared

## cloudflared login

登録する予定のドメインでログインする

```
cloudflared tunnel login
```

## トンネル作成

トンネル名でトンネルを作成する。
UUID が付与されるので控えておく。
`<tunnel-name>`の部分を自分のトンネル名に置き換える。

Cloudflare の Tunnel とは、インターネット上でプライベートな接続を確立し、サーバーやアプリケーションへの安全なアクセスを提供するためのツール。
自分のサーバーと cloudflare の専用回線のようなもの。

```
root@tool-box:~# cloudflared tunnel create <tunnel-name>
Tunnel credentials written to /root/.cloudflared/<uuid>.json. cloudflared chose this file based on where your origin certificate was found. Keep this file secret. To revoke these credentials, delete the tunnel.

Created tunnel <tunnel-name> with id <uuid>

```

## ルーティング設定

cloudflare の DNS に任意のサブドメインのアクセスが来たら、設定したトンネルにトラフィックを流すように設定する

```
root@tool-box:~/.cloudflared# cloudflared tunnel route dns <tunnel-name> <subdomain-name>
2023-12-10T02:20:24Z INF Added CNAME assam.edge2992.dev which will route to this tunnel tunnelID=<uuid>
```

## ルーティング設定（内部ネットワーク向け）

トンネルからトラフィックが来たら、そのトラフィックをどこに向けるかを設定する。
.cloudflared/config.yml を記入する

```
url: http://localhost:8000
tunnel: <Tunnel-UUID>
credentials-file: /root/.cloudflared/<Tunnel-UUID>.json

```

WARP（VPN）接続するプライベートネットワーク用なら warp-routing を True にする。

```
tunnel: <Tunnel-UUID>
credentials-file: /root/.cloudflared/<Tunnel-UUID>.json
warp-routing:
    enabled: true

```

## 起動

```
cloudflared tunnel run <tunnel-name>

```

### デバッグ

```
cloudflared tunnel info <tunnel-name>

```

curl などで公開できていることが確認できたら Ctrl+C などで閉じる。

## サービス登録

service ファイルを作成して、サービスを起動させる。
/root/.cloudflared/config.yml で書いた設定ファイルが/etc/cloudflared/config.yml にコピーされていた。

```
cloudflared service install
cloudflared start cloudflared
```

### 確認

```
systemctl status cloudflared
```

## 参考

- https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/get-started/create-local-tunnel/
- https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/configure-tunnels/local-management/as-a-service/linux/
