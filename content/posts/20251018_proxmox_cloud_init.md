---
title: "Proxmox VEでcloud-init対応のUbuntu 24.04テンプレートを作成する手順"
author: ["えじっさ"]
date: 2025-10-18T14:27:34+09:00
tags: ["proxmoxVE","cloud-init","Ubuntu"]
images:
  - "img/og/20251018_proxmox_cloud_init.png"
categories: ["proxmoxVE","cloud-init","Ubuntu"]
draft: false
---

Proxmox VE で Ubuntu 24.04 の VM をすぐに作成し、検証を繰り返せる環境を用意したいと思い、cloud-init を使って VM の雛形を作成しました。


Proxmox VEではVMをテンプレート化しておくことができます。
しかし、色々な設定をしたVMをしばらく放置しておくと、何を設定したのか忘れてしまいます。

cloud-initは, Cloud環境でVMの初期化を自動化するためのデファクトスタンダードなツールです。
proxmoxVEはcloud-initに対応しているので、cloud-initを使ってVMの雛形を作成することにしました。

## cloud-initとは

cloud-initは、初回起動時にユーザーデータを読み取ってVMを初期化する仕組みです。
Proxmox VEでは、cloud-init用のドライブ (ide2 など) にユーザーデータISOを自動生成して接続することで、
同様の挙動をローカル環境でも再現できます。

これにより、初期設定（ユーザー作成、SSH鍵登録、パッケージインストールなど）を自動化でき、どのVMも同じ状態から起動できるようになります。

## cloud-initのsnippetを作成する

次のようにcloud-initのsnippetを作成しました。
ubuntuユーザーを作成し、sudo権限を付与し、SSH公開鍵認証を設定しています。
基本的なパッケージのインストールとタイムゾーンの設定、UFWの設定も行っています。


```yaml
#cloud-config
timezone: Asia/Tokyo
locale: en_US.UTF-8

users:
  - name: ubuntu
    gecos: Ubuntu User
    sudo: ALL=(ALL) NOPASSWD:ALL
    groups: sudo
    shell: /bin/bash
    ssh_authorized_keys:
      - ssh-ed25519 <YOUR_SSH_PUBLIC_KEY>

package_update: true
package_upgrade: true
packages:
  - vim
  - curl
  - git
  - htop
  - net-tools
  - ufw

runcmd:
  - timedatectl set-timezone Asia/Tokyo
  - ufw allow 22/tcp
  - ufw --force enable
  - echo "Provision complete at $(date)" > /etc/motd
```

## proxmoxVE上にcloud-initのsnippetを登録する

`/var/lib/vz/snippets`に上記のcloud-initのsnippetを`ubuntu-init.yaml`として保存します。
`/var/lib/vz`というディレクトリはproxmoxVEのデフォルトのストレージパスです。
/etc/pve/storage.cfgで確認できます。


```sh
sudo cat /etc/pve/storage.cfg

dir: local
        path /var/lib/vz
        content backup,iso,vztmpl,snippets

lvmthin: local-lvm
        thinpool data
        vgname pve
        content images,rootdir
```

## proxmoxVE上でqmコマンドを使ってVMを作成する

まずは仮想マシンの基本構成を作成します。  
ここではメモリ4GB・2コア・VirtIOネットワークを指定しています。

次のようにqmコマンドを使ってVMを作成します。
テンプレート化するために、DHCPでIPアドレスを取得するように設定しています。

元となるimageは、cloud-init対応のUbuntu24.04をqcow2形式でダウンロードして、`/var/lib/vz/template/qcow2/`に保存しておきます。

```sh
VMID=130
VMNAME=ubuntu-24-cloudinit
STORAGE=local-lvm

# VMの箱を作成
sudo qm create $VMID --name $VMNAME --memory 4096 --cores 2 --net0 virtio,bridge=vmbr0
sudo qm importdisk $VMID /var/lib/vz/template/qcow2/noble-server-cloudimg-amd64.img local-lvm

# ディスクをアタッチしてリサイズ
DISK_REF=$(sudo pvesh get /nodes/$(hostname -s)/storage/$STORAGE/content --output-format json | jq -r --arg id "$VMID" '.[] | select(.volid | test("vm-\($id)-disk-0$")) | .volid')
sudo qm set $VMID --scsihw  virtio-scsi-single --scsi0 "$DISK_REF"
sudo qm resize $VMID scsi0 40G

# cloud-initの設定
sudo qm set $VMID --ide2 local-lvm:cloudinit
sudo qm set $VMID --cicustom "user=local:snippets/ubuntu-init.yaml"
sudo qm set $VMID --ipconfig0 ip=dhcp
sudo qm set $VMID --boot order=scsi0
sudo qm set $VMID --serial0 socket --vga serial0 
sudo qm set $VMID --agent enabled=1
```

次のように起動します。
直前に`cloudinit update`でcloud-initの設定を反映させます。

```bash
sudo qm cloudinit update $VMID
sudo qm start $VMID
sudo qm terminal $VMID
```

cloud-final.serviceが完了していることを確認します。

```sh
[   85.302809] cloud-init[1060]: Cloud-init v. 25.2-0ubuntu1~24.04.1 finished at Sat, 18 Oct 2025 05:14:00 +0000. Datasource DataSourceNoCloud [seed=/dev/sr0].  Up 85.29 seconds
[  OK  ] Finished cloud-final.service - Cloud-init: Final Stage.
[  OK  ] Reached target cloud-init.target - Cloud-init target.
```

## VMをテンプレートとする

起動したVMを停止し、cloud-initの設定を更新してからテンプレート化します。

```sh
sudo qm stop $VMID
sudo qm cloudinit update $VMID
sudo qm template $VMID
```

## テンプレートからVMを立ち上げる


次のようにテンプレートからVMを立ち上げます。
今回は立ち上げる際に固定IPアドレスを設定しています。
立ち上げたVMはsshで接続できます。

```sh
TEMPLATE_ID=130
VMID=131
sudo qm clone $TEMPLATE_ID $VMID --name test-vm --full
sudo qm set $VMID --ipconfig0 ip=192.168.0.165/24,gw=192.168.0.1 --nameserver 1.1.1.1
sudo qm cloudinit update $VMID
sudo qm start $VMID
```

## まとめ

Proxmox VE で cloud-init を使うことで、SSH公開鍵認証の設定や初期パッケージの導入、UFWの有効化などを自動化できます。
これにより、毎回手動で設定する手間が省け、検証環境を短時間で再現できるようになります。
テンプレート化した VM をベースに、用途ごとにクローンを作る運用にも応用可能です。

