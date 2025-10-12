---
title: "2025年でもUbuntu 16.04 で netdata を動かす"

author: ["えじっさ"]
date: 2025-10-13T04:13:47+09:00
tags: ['netdata', 'Ubuntu16.04']
images:
  - "img/og/20251012_netdata_ubuntu16.png"
categories: ['netdata', 'Ubuntu16.04']
draft: false
---

netdataの推奨されるインストール方法は kickstart.sh を使うこと。
しかし、netdataのページで推奨されているcommandをUbuntu 16.04で実行すると, netdata-repo-edge_5-1+ubuntu16.04_all.deb が 404 になる。


static-only でインストールすれば, Ubuntu 16.04 でも動く。


## 成功例

```sh
curl https://get.netdata.cloud/kickstart.sh > /tmp/netdata-kickstart.sh && sh /tmp/netdata-kickstart.sh --static-only --release-channel stable --claim-token <token> --claim-rooms <room-uuid> --claim-url https://app.netdata.cloud
```

## 失敗例

kickstart.sh でインストールしようとすると,netdata-repo-edge_5-1+ubuntu16.04_all.deb が 404 になる。

```sh
isucon@ip-172-31-44-71:~$ curl https://get.netdata.cloud/kickstart.sh > /tmp/netdata-kickstart.sh && sh /tmp/netdata-kickstart.sh --nightly-channel --claim-token <token> --claim-rooms <room-uuid> --claim-url https://app.netdata.cloud
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 95353  100 95353    0     0   440k      0 --:--:-- --:--:-- --:--:--  441k

 --- Using /tmp/netdata-kickstart-rnlueatEcK as a temporary directory. ---
 --- Checking for existing installations of Netdata... ---
 --- No existing installations of netdata found, assuming this is a fresh install. ---
 --- Attempting to install using native packages... ---
 --- Checking for availability of repository configuration package. ---
[/tmp/netdata-kickstart-rnlueatEcK]$ /usr/bin/curl --fail -q -sSL --connect-timeout 10 --retry 3 --output /tmp/netdata-kickstart-rnlueatEcK/netdata-repo-edge_5-1+ubuntu16.04_all.deb https://repo.netdata.cloud/repos/repoconfig/ubuntu/xenial/netdata-repo-edge_5-1+ubuntu16.04_all.deb
curl: (22) The requested URL returned error: 404 Not Found
 FAILED

[/tmp/netdata-kickstart-rnlueatEcK]$ wget -T 15 -O /tmp/netdata-kickstart-rnlueatEcK/netdata-repo-edge_5-1+ubuntu16.04_all.deb https://repo.netdata.cloud/repos/repoconfig/ubuntu/xenial/netdata-repo-edge_5-1+ubuntu16.04_all.deb
--2025-10-13 04:17:13--  https://repo.netdata.cloud/repos/repoconfig/ubuntu/xenial/netdata-repo-edge_5-1+ubuntu16.04_all.deb
Resolving repo.netdata.cloud (repo.netdata.cloud)... 2606:4700:10::6814:1602, 2606:4700:10::ac42:aad8, 104.20.22.2, ...
Connecting to repo.netdata.cloud (repo.netdata.cloud)|2606:4700:10::6814:1602|:443... connected.
HTTP request sent, awaiting response... 302 Found
Location: https://repo.netdata.cloud/no-such-repo [following]
--2025-10-13 04:17:13--  https://repo.netdata.cloud/no-such-repo
Reusing existing connection to [repo.netdata.cloud]:443.
HTTP request sent, awaiting response... 404 Not Found
2025-10-13 04:17:13 ERROR 404: Not Found.

 FAILED

The following non-fatal warnings or errors were encountered:

  - Command "/usr/bin/curl --fail -q -sSL --connect-timeout 10 --retry 3 --output /tmp/netdata-kickstart-rnlueatEcK/netdata-repo-edge_5-1+ubuntu16.04_all.deb https://repo.netdata.cloud/repos/repoconfig/ubuntu/xenial/netdata-repo-edge_5-1+ubuntu16.04_all.deb" failed with exit code 22.
  - Command "wget -T 15 -O /tmp/netdata-kickstart-rnlueatEcK/netdata-repo-edge_5-1+ubuntu16.04_all.deb https://repo.netdata.cloud/repos/repoconfig/ubuntu/xenial/netdata-repo-edge_5-1+ubuntu16.04_all.deb" failed with exit code 8.

 ABORTED  Failed to download repository configuration package. This is usually a result of a networking issue.

For community support, you can connect with us on:
  - GitHub: https://github.com/netdata/netdata/discussions
  - Discord: https://discord.gg/5ygS846fR6
  - Our community forums: https://community.netdata.cloud/
Root privileges required to run rm -rf /tmp/netdata-kickstart-rnlueatEcK
[/home/isucon]$ sudo rm -rf /tmp/netdata-kickstart-rnlueatEcK
 OK
```
