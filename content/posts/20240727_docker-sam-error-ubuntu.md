---
title: "[Ubuntu] Lambdaのローカル実行 (sam local invoke) でdockerが認識されない"
author: ["えじっさ"]
date: 2024-07-27T21:31:12+09:00
tags: ["AWS", "Lambda"]
images:
  - "img/og/20240727_docker-sam-error-ubuntu.png"
categories: ["AWS", "Lambda"]
draft: false
---

## 事象

AWS SAM (Serverless Application Model)を利用してlambda関数をローカル実行しようとした際、次のエラーが発生することがあります。

```bash
$ echo {} | sam local invoke HelloWorldFunction
/usr/lib/python3/dist-packages/paramiko/transport.py:237: CryptographyDeprecationWarning: Blowfish has been deprecated and will be removed in a future release
  "class": algorithms.Blowfish,
Error: Running AWS SAM projects locally requires Docker. Have you got it installed and running?
```

dockerのインストールができていない場合はdockerをインストールしてください。
ここでは、dockerは起動しているもののSAM CLIがdockerを認識していない場合の対応について解説します。
次のコマンドを実行することでdocker daemonが起動しているかどうかを確認できます。
筆者の環境はUbuntu 22.04です。

```bash
$ docker ps

```

## 解決策

DOCKER_HOSTをdocker desktopで起動しているcontextで指定する必要があります。

```
$ echo {} | DOCKER_HOST=unix:///home/edge2992/.docker/desktop/docker.sock sam local invoke HelloWorldFunction

```

samが見に行っているdockerのcontextがデーモンとして起動しているdockerと異なる際に発生しているようです。
dockerコマンド外からの接続には指定しているcontextが使われず、DOCKER_HOSTが利用されています。
contextは次のように確認できます。

```bash
$ docker context ls
NAME                TYPE                DESCRIPTION                               DOCKER ENDPOINT                                     KUBERNETES ENDPOINT   ORCHESTRATOR
default             moby                Current DOCKER_HOST based configuration   unix:///var/run/docker.sock                                               
desktop-linux *     moby                Docker Desktop                            unix:///home/edge2992/.docker/desktop/docker.sock      

```

この手順に従うことで、sam local invokeでのLambda関数のローカル実行が正常に行えるようになります。

## 参考

- [Bug: Error: Docker is not reachable (even though it is!) #4329](https://github.com/aws/aws-sam-cli/issues/4329)









