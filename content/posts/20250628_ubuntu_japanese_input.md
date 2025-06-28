---
title: "VSCode, Chromeがibus-mozcで日本語入力できなかったのでfxitx5に移行した (Ubuntu 22.04)"
author: ["えじっさ"]
date: 2025-06-28T12:20:28+09:00
tags: ["ubuntu"]
images:
  - "img/og/20250628_ubuntu_japanese_input.png"
categories: ["ubuntu"]
draft: false
---


Ubuntu 22.04で日本語環境を構築した際、**VSCodeやChrome（Electron系アプリ）で日本語入力ができない問題**に遭遇しました。

結論として、**fcitx5へ移行したら解決した**ので、備忘録として残します。

## 起きていた問題

UBuntu 22.04 (GNOME + X11 + GTK3) 環境で


- **日本語入力できる:** Terminal, Firefox, LibreOffice
- **日本語入力できない:** Chrome, VSCode

という状況になりました。
ibusのほうで色々ためしてみたもののうまく設定できなかったので、fcitx5に移行することにしました。

ibusの場合, **Electron系アプリ（Chrome, VSCode）や一部QtアプリではIME連携が不安定**になることがあるようです。


## fcitx5移行前の設定


```sh
echo $GTK_IM_MODULE
echo $QT_IM_MODULE
echo $XMODIFIERS

# 出力　
GTK_IM_MODULE=ibus
QT_IM_MODULE=ibus
XMODIFIERS=@im=ibus
```

## fcitx5への移行手順

### パッケージインストール

GTK/Qtフロントエンド込みでインストールします。

```sh
$ sudo apt update
$ sudo apt install \
  fcitx5 fcitx5-mozc \
  fcitx5-frontend-gtk4 fcitx5-frontend-gtk3 \
  fcitx5-frontend-qt5 \
  fcitx5-config-qt
```

### `fcitx5`への切り替え

以下のコマンドを実行します。

```sh
$ im-config -n fcitx5
```
`~/.xinputrc`に`rum_im fcitx5`が追加されるようになります。


### Mozcの有効化

fcitx5-config-qt を起動し、GUIから日本語（Mozc）を追加しました。


### 設定確認

ログアウトしてから再度ログインして、正しく設定されているか確認しました。

```sh
$ echo "GTK_IM_MODULE=$GTK_IM_MODULE"
echo "QT_IM_MODULE=$QT_IM_MODULE"
echo "XMODIFIERS=$XMODIFIERS"
env | grep -E 'IM_MODULE|MODIFIERS'

# 出力
GTK_IM_MODULE=fcitx
QT_IM_MODULE=fcitx
XMODIFIERS=@im=fcitx
QT_IM_MODULE=fcitx
GTK_IM_MODULE=fcitx
CLUTTER_IM_MODULE=xim
XMODIFIERS=@im=fcitx
```


```sh
$ im-config -m

# 出力
default
fcitx5
ibus

ibus
```

im-configを見るとibusが利用されているように見えますが、`~/.xinputrc`でfcitx5を設定しているのでfcitxが動いているようです。
問題ないみたいです。


## ibus関連設定の後片付け

### GNOME入力設定からJapanese (Mozc)を削除

ibusで設定していたmozcを削除しました。　


### 古い ibus 関連プロセスを停止

```sh
ibus exit
killall ibus-daemon
```


### ibus の残存設定をディレクトリごと削除

```sh
rm -rf ~/.config/ibus
rm -rf ~/.local/share/ibus
```

### ibus関連パッケージ削除はしないほうがよさそう

ibusのライブラリを削除してみたところ, GUIのセッションを扱っているgdm3が自動削除されてしまい、GUI画面が落ちてしまいました。
ibus自体はGNOMEへの依存があるため、アインストールはせず、fcitx5のみをIMEとして設定しておく運用がよさそうです。


この設定で、問題なく日本語設定ができるようになりました。

