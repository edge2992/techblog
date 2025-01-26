---
title: "ISUCONで学ぶObservability入門"
author: ["えじっさ"]
date: 2023-12-16T12:05:48+09:00
tags: []
images:
  - "img/og/Isucon_observability_basics.png"
categories: []
draft: false
---

限られた時間（業務時間）のなかでシステムのパフォーマンスを改善するときには
メトリクスを見ながら効果のある修正を行っていきたいです。

具体的には Web のパフォーマンスチューニングを行う上で次のような指標を計測したいです。

- cpu, load, ram, network, i/o といったサーバーの概要を捉える指標
- DB のクエリ別のリソース使用状況 (slow-query-log)
- API のエンドポイント別のパフォーマンス
- アプリケーションの関数ごとのリソース使用状況

Web パフォーマンスチューニングの業界では、LINE\Yahoo 社が主催している「ISUCON」と呼ばれるパフォーマンスチューニングコンテストが年に一度開かれています。
今年は 11/25 に ISUCON13 が開催され私も参加してきました。

ISUCON は競技である以上、
デプロイと計測には定石が共有されています。

本記事では、ISUCON に参加するにあたって勉強したプロファイル(計測)手法についてまとめます。

(導入とカスタマイズができるだけ簡単なもの&無料なものが好まれるため、長期的な計測をする際にはもっといい方法が沢山あると思います。)

## netdata

サーバーのモニタリングツールです。
アプリケーションごとの CPU 使用率やディスク IO、ネットワークなどの確認に使っています。

![netdata](/img/isucon_observability_basics/netdata.png)

## pt-query-digester

PECONA 社が公開している MySQL のスロークエリの統計を取るコマンドツールです。
次のようなサマリーとそれぞれの詳細を知れます。
Response time は総時間, Calls はコール数, R/Call はクエリ1回あたりの時間です。
詳細を見ると Exec time, Lock time などの分布を確認できます。
今回の計測では全体の 23%の時間を占めているこのクエリが悪さをしていそうです。

```sql
SELECT IFNULL(SUM(l2.tip), 0) FROM users u
		INNER JOIN livestreams l ON l.user_id = u.id
		INNER JOIN livecomments l2 ON l2.livestream_id = l.id
		WHERE u.id = 618\G
```

### pt-query-digester サマリ

```

# 11.4s user time, 10ms system time, 30.62M rss, 36.66M vsz
# Current date: Sat Nov 25 06:41:12 2023
# Hostname: ip-192-168-0-13
# Files: /tmp/slow_query_20231025063929.log
# Overall: 171.00k total, 66 unique, 2.59k QPS, 5.16x concurrency ________
# Time range: 2023-11-25T06:39:37 to 2023-11-25T06:40:43
# Attribute          total     min     max     avg     95%  stddev  median
# ============     ======= ======= ======= ======= ======= ======= =======
# Exec time           341s     1us   350ms     2ms     6ms     8ms   194us
# Lock time          978ms       0    38ms     5us     1us   200us     1us
# Rows sent        640.81k       0   7.40k    3.84    0.99   70.59    0.99
# Rows examine      37.03M       0  14.12k  227.08   49.17   1.42k    0.99
# Query size        10.12M       5     435   62.04  158.58   50.64   40.45

# Profile
# Rank Query ID                      Response time Calls R/Call V/M   Item
# ==== ============================= ============= ===== ====== ===== ====
#    1 0xF1B8EF06D6CA63B24BFF433E... 78.7247 23.1% 10412 0.0076  0.02 SELECT users livestreams livecomments
#    2 0x64CC8A4E8E4B390203375597... 66.6257 19.6%  1003 0.0664  0.01 SELECT ng_words
#    3 0x59F1B6DD8D9FEC059E55B3BF... 25.8362  7.6%   779 0.0332  0.01 SELECT reservation_slots
#    4 0xEDE18C1523658A19E07525EA... 20.7467  6.1%   297 0.0699  0.01 SELECT ng_words
#    5 0xFFFCA4D67EA0A788813031B8... 16.0878  4.7%  6484 0.0025  0.01 COMMIT
#    6 0xD6032FE08E1FE706A928B8B7... 15.9029  4.7% 28505 0.0006  0.00 SELECT livestreams
#    7 0xDB74D52D39A7090F224C4DEE... 14.8011  4.3% 10414 0.0014  0.00 SELECT users livestreams reactions
#    8 0xEA1E6309EEEFF9A6831AD2FB... 13.4922  4.0% 26138 0.0005  0.00 SELECT users
#    9 0xB08B7B7486D2DFE2F2FE9CE7...  8.6992  2.6%   115 0.0756  0.01 SELECT ng_words
#   10 0xFD38427AE3D09E3883A680F7...  7.3614  2.2%  8188 0.0009  0.00 SELECT livestreams livecomments
#   11 0xC499D81D570D361DB61FC43A...  7.1177  2.1%  8190 0.0009  0.00 SELECT livestreams reactions
#   12 0x859BBB7E9D760686137A9444...  7.0589  2.1%   261 0.0270  0.01 DELETE records
#   13 0xA3401CA3ABCC04C3AB221DB8...  6.1253  1.8%    70 0.0875  0.02 UPDATE reservation_slots
#   14 0x7F9C0C0BA9473953B723EE16...  5.8574  1.7%    71 0.0825  0.01 SELECT reservation_slots
#   15 0x50445823239A29D3A1BF75B2...  5.7238  1.7%  8845 0.0006  0.00 SELECT icons
#   16 0xF5C7940F264BAB49FBD63A1F...  5.5437  1.6%  9506 0.0006  0.00 SELECT icons
#   17 0x3F155F5E71EFF856F0CF7B84...  5.2305  1.5%  9111 0.0006  0.02 SELECT users
#   18 0x41F805E95754958A974F41AE...  3.8622  1.1%   288 0.0134  0.01 SELECT livecomments
#   19 0x9AC623FA477E73A44D191D29...  3.6877  1.1%   522 0.0071  0.01 SELECT records
#   20 0x9E2DA589A20EC24C34E11DDE...  2.1351  0.6% 15127 0.0001  0.00 START
#   21 0x42EF7D7D98FBCC9723BF896E...  2.0447  0.6%   261 0.0078  0.01 SELECT records
#   22 0xFFF66E9B3D962FA319C8068B...  2.0285  0.6%  8891 0.0002  0.00 ROLLBACK
#   23 0xF3A502CCF34F7DA288CC1B75...  1.7494  0.5%  1003 0.0017  0.01 INSERT livecomments
#   24 0x4B6FA79E206C6CED71D433A2...  1.6588  0.5%  1492 0.0011  0.00 SELECT
#   25 0x38BC86A45F31C6B1EE324671...  1.4736  0.4%   672 0.0022  0.00 SELECT themes
#   26 0xDA556F9115773A1A99AA0165...  1.2149  0.4%  1566 0.0008  0.17 ADMIN PREPARE
#   27 0xB78E63D0D9C72DDDAB7A3E53...  0.8256  0.2%   696 0.0012  0.00 SELECT livecomments
#   28 0xAD0C28443E1E5CFAFF1569DB...  0.6944  0.2%   692 0.0010  0.00 SELECT reactions
#   29 0x9EAD6C0CE525E3693EE27FFC...  0.6860  0.2%   759 0.0009  0.11 SELECT livestreams
#   30 0xF7144185D9A142A426A36DC5...  0.6688  0.2%  1108 0.0006  0.00 SELECT livestream_tags
#   31 0x24C44C3518CE12293EF12410...  0.6642  0.2%   310 0.0021  0.00 SELECT livestreams
#   32 0x3D83BC87F3B3A00D571FFC81...  0.6585  0.2%   261 0.0025  0.00 SELECT records
#   33 0x5AEB6E4A781A3854CF642125...  0.5565  0.2%   691 0.0008  0.00 INSERT reactions
#   34 0x0B69134CEB7DC9D7EACFAF38...  0.5083  0.1%   288 0.0018  0.01 DELETE livecomments
#   35 0x651E3772B8767A368CB47EE7...  0.4191  0.1%    12 0.0349  0.01 SELECT livestream_tags
#   36 0x77FB9E134D073862D1E78FEE...  0.4129  0.1%   261 0.0016  0.00 INSERT records
#   37 0xD2A0864774622BA36F655749...  0.4016  0.1%   250 0.0016  0.01 INSERT themes
#   38 0x050F7D44808F43E5D33D0B90...  0.3931  0.1%     3 0.1310  0.00 SELECT livestreams
#   39 0x8F7679D452333ED3C7D60D22...  0.3753  0.1%  1816 0.0002  0.01 ADMIN RESET STMT
#   40 0x544239977D2094F805A7B062...  0.2831  0.1%    82 0.0035  0.12 SELECT tags
# MISC 0xMISC                         2.2199  0.7%  5556 0.0004   0.0 <26 ITEMS>

```

### pt-query-digester 詳細 (Query 1)

```

# Query 1: 200.23 QPS, 1.51x concurrency, ID 0xF1B8EF06D6CA63B24BFF433E06CCEB22 at byte 13967751
# This item is included in the report because it matches --limit.
# Scores: V/M = 0.02
# Time range: 2023-11-25T06:39:46 to 2023-11-25T06:40:38
# Attribute    pct   total     min     max     avg     95%  stddev  median
# ============ === ======= ======= ======= ======= ======= ======= =======
# Count          6   10412
# Exec time     23     79s   128us    92ms     8ms    33ms    12ms     2ms
# Lock time     10   100ms       0     8ms     9us     1us   153us     1us
# Rows sent      1  10.17k       1       1       1       1       0       1
# Rows examine  17   6.62M       0   2.82k  666.52   2.16k  966.25    8.91
# Query size    16   1.64M     163     166  164.99  158.58       0  158.58
# String:
# Databases    isupipe
# Hosts        localhost
# Users        isucon
# Query_time distribution
#   1us
#  10us
# 100us  ################################################################
#   1ms  ###################################################
#  10ms  ######################################
# 100ms
#    1s
#  10s+
# Tables
#    SHOW TABLE STATUS FROM `isupipe` LIKE 'users'\G
#    SHOW CREATE TABLE `isupipe`.`users`\G
#    SHOW TABLE STATUS FROM `isupipe` LIKE 'livestreams'\G
#    SHOW CREATE TABLE `isupipe`.`livestreams`\G
#    SHOW TABLE STATUS FROM `isupipe` LIKE 'livecomments'\G
#    SHOW CREATE TABLE `isupipe`.`livecomments`\G
# EXPLAIN /*!50100 PARTITIONS*/
SELECT IFNULL(SUM(l2.tip), 0) FROM users u
		INNER JOIN livestreams l ON l.user_id = u.id
		INNER JOIN livecomments l2 ON l2.livestream_id = l.id
		WHERE u.id = 618\G
```

## alp

リバースプロキシのアクセスログの集計ツールです。
次のようなメトリクスを収集できます。
エンドポイントは正規表現でグループ化できます。
/api/user/[a-zA-Z0-9]+/icon, /api/user/[a-zA-Z0-9]+/statistics が重いです。

```
+-------+-----+-----+------+--------+---------------------------------------+-------+--------+---------+--------+--------+
| COUNT | 5XX | 4XX | 2XX  | METHOD |                  URI                  |  MIN  |  MAX   |   SUM   |  AVG   |  P90   |
+-------+-----+-----+------+--------+---------------------------------------+-------+--------+---------+--------+--------+
| 8851  | 0   | 2   | 8849 | GET    | /api/user/[a-zA-Z0-9]+/icon           | 0.004 | 0.424  | 156.472 | 0.018  | 0.040  |
| 13    | 0   | 5   | 8    | GET    | /api/user/[a-zA-Z0-9]+/statistics     | 2.540 | 20.004 | 149.436 | 11.495 | 20.004 |
| 1066  | 0   | 6   | 1060 | POST   | /api/livestream/[0-9]+/livecomment    | 0.004 | 0.316  | 113.868 | 0.107  | 0.156  |
| 771   | 0   | 1   | 770  | GET    | /api/livestream/[0-9]+/livecomment    | 0.004 | 0.392  | 56.888  | 0.074  | 0.160  |
| 806   | 0   | 2   | 804  | GET    | /api/livestream/[0-9]+/reaction       | 0.004 | 0.336  | 49.800  | 0.062  | 0.140  |
| 263   | 1   | 3   | 259  | POST   | /api/register                         | 0.004 | 0.684  | 49.304  | 0.187  | 0.268  |
| 100   | 0   | 4   | 96   | POST   | /api/livestream/reservation           | 0.004 | 1.304  | 46.956  | 0.470  | 0.944  |
| 5     | 0   | 3   | 2    | GET    | /api/livestream/[0-9]+/statistics     | 2.564 | 13.684 | 42.768  | 8.554  | 13.684 |
| 298   | 0   | 0   | 298  | GET    | /api/livestream/[0-9]+/ngwords        | 0.004 | 0.296  | 28.224  | 0.095  | 0.148  |
| 116   | 0   | 0   | 116  | POST   | /api/livestream/[0-9]+/moderate       | 0.008 | 0.424  | 20.108  | 0.173  | 0.272  |
| 333   | 0   | 1   | 332  | GET    | /api/livestream/search?               | 0.008 | 0.832  | 18.784  | 0.056  | 0.080  |
| 715   | 0   | 0   | 715  | POST   | /api/livestream/[0-9]+/reaction       | 0.004 | 0.172  | 18.128  | 0.025  | 0.056  |
| 857   | 0   | 0   | 857  | GET    | /api/livestream                       | 0.004 | 0.344  | 15.024  | 0.018  | 0.044  |
| 456   | 34  | 0   | 422  | GET    | /api/livestream/[0-9]+/report         | 0.004 | 0.180  | 9.704   | 0.021  | 0.052  |
| 260   | 0   | 0   | 260  | POST   | /api/icon                             | 0.004 | 0.184  | 9.152   | 0.035  | 0.076  |
| 1     | 0   | 0   | 1    | POST   | /api/initialize                       | 8.472 | 8.472  | 8.472   | 8.472  | 8.472  |
| 267   | 0   | 2   | 265  | POST   | /api/login                            | 0.004 | 0.148  | 4.972   | 0.019  | 0.044  |
| 86    | 0   | 0   | 86   | GET    | /api/tag                              | 0.004 | 0.204  | 2.088   | 0.024  | 0.056  |
| 73    | 0   | 0   | 73   | POST   | /api/livestream/[0-9]+/enter          | 0.004 | 0.084  | 1.532   | 0.021  | 0.048  |
| 64    | 0   | 0   | 64   | DELETE | /api/livestream/[0-9]+/exit           | 0.004 | 0.124  | 1.228   | 0.019  | 0.044  |
| 12    | 0   | 0   | 12   | GET    | /api/user/[a-zA-Z0-9]+/theme          | 0.004 | 0.032  | 0.116   | 0.010  | 0.020  |
| 1     | 0   | 0   | 1    | GET    | /api/user/yasuhiro280/livestream      | 0.024 | 0.024  | 0.024   | 0.024  | 0.024  |
| 1     | 0   | 0   | 1    | GET    | /api/user/mtanaka1/livestream         | 0.012 | 0.012  | 0.012   | 0.012  | 0.012  |
| 1     | 0   | 0   | 1    | GET    | /api/user/kanasasaki0/livestream      | 0.008 | 0.008  | 0.008   | 0.008  | 0.008  |
| 1     | 0   | 0   | 1    | GET    | /api/user/csasaki0/livestream         | 0.008 | 0.008  | 0.008   | 0.008  | 0.008  |
| 1     | 0   | 0   | 1    | GET    | /api/user/yukitanaka0/livestream      | 0.008 | 0.008  | 0.008   | 0.008  | 0.008  |
| 1     | 0   | 0   | 1    | GET    | /api/user/yamazakikyosuke0/livestream | 0.004 | 0.004  | 0.004   | 0.004  | 0.004  |
| 1     | 0   | 0   | 1    | GET    | /api/user/test                        | 0.004 | 0.004  | 0.004   | 0.004  | 0.004  |
| 1     | 0   | 0   | 1    | GET    | /api/livestream/7497                  | 0.000 | 0.000  | 0.000   | 0.000  | 0.000  |
| 1     | 0   | 0   | 1    | GET    | /api/payment                          | 0.000 | 0.000  | 0.000   | 0.000  | 0.000  |
| 3     | 0   | 0   | 3    | GET    | /api/user/me                          | 0.000 | 0.000  | 0.000   | 0.000  | 0.000  |
+-------+-----+-----+------+--------+---------------------------------------+-------+--------+---------+--------+--------+
```

## pprof

Go のプロファイリングツールで CPU 負荷や処理時間、メモリ使用量を計測して表示してくれます。
次のように CPU の実行時間をフレームグラフにすると見やすいです。
上から下に関数がよびだされています。

![netdata](/img/isucon_observability_basics/pprof-sample.png)

## まとめ

モニタリングは継続的なテストとも言われています。
STG, PROD 環境問わず、こうした指標を常に持っておくことで安心してデプロイできるのではないかと思います。
