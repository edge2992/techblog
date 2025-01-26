---
title: "proxmox上のTrueNASにzpoolをマウントする方法"
date: 2023-05-07T19:04:32+09:00
tags: ["proxmox", "TrueNAS"]
categories: ["proxmox"]
draft: false
---

この記事では、あらかじめ作成されているzpoolをproxmox上のTrueNASにマウントする方法を説明します。次のようなディスク構成のZFSをTrueNASにマウントすることを目的としています。

```bash
root@pve:~# fdisk -l
Disk /dev/sda: 3.64 TiB, 4000787030016 bytes, 7814037168 sectors
Disk model: WDC WD40EZAZ-00S
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 4096 bytes
I/O size (minimum/optimal): 4096 bytes / 4096 bytes
Disklabel type: gpt
Disk identifier: <DISK_IDENTIFIER>

Device       Start        End    Sectors  Size Type
/dev/sda1      128    4194431    4194304    2G FreeBSD swap
/dev/sda2  4194432 7814037127 7809842696  3.6T FreeBSD ZFS
```

## proxmoxに登録していたzpoolをexportする (必要な場合)

もし試行錯誤の過程でproxmoxにzpoolを登録してしまっていた場合は、TrueNASとproxmoxの両方に同時にマウントするのは適切ではないため、proxmoxからzpoolをexportする必要があります。

1. /etc/pve/storage.cfgを編集してzpoolのエントリーを消す
2. `zpool export <POOL_NAME>`でpoolをエクスポートする

```bash
root@pve:~# zpool list
    SIZE  ALLOC   FREE  CKPOINT  EXPANDSZ   FRAG    CAP  DEDUP    HEALTH  ALTROOT
pool-01  3.62T  4.72G  3.62T        -         -     0%     0%  1.00x    ONLINE  -
root@pve:~# zpool export <POOL_NAME>
root@pve:~# zpool list
no pools available
```

## TrueNASにディスクをマウントする

ディスク名（sda, sdbなど）は変更される可能性があるため、ディスクのシリアルナンバーを使ってマウントします。

1. `lsblk -o +MODEL,SERIAL`でシリアルナンバーを確認する
2. /dev/disk/by-idでディスクのパスを確認する
3. proxmox上のTrueNASのVMに対して、ディスクをSCSIデバイスとして登録する

```bash
qm set <VM_ID> -scsi1 /dev/disk/by-id/<TARGET_DISK>
```

## TrueNASのGUIで既存のzpoolを登録する

TrueNASのGUIのStorage/Poolの画面から、次の手順で既存のzpoolを登録します。

1. "ADD"ボタンをクリックします。
2. "import an existing pool"を選択し、必要な情報を入力します。
3. "Import"ボタンを押して、zpoolをTrueNASに登録します。

これで、TrueNASにzpoolがマウントされました。
