---
title: "運用で使える咄嗟のコマンドリスト"
author: ["えじっさ"]
date: 2024-04-30T22:08:50+09:00
tags: ["linux"]
images:
  - "img/og/20240430_operation_command.png"
categories: ["linux"]
---

障害対応では即時の対応が求められます。
コマンドがわからなくてあたふたしていると足手まといになってしまうので、生ログの解析に役立つコマンドを復習しました。

## 障害対応で役立つコマンドたち

### [cut](https://www.ibm.com/docs/ja/aix/7.1?topic=c-cut-command)

- ある列を抽出するときに利用する。
- `-d`が delimiter, `-f`で何番目の列を取り出すか指定する。
- 1-indexed
- file がない場合は標準入力を利用する。file は複数指定できる。

```csv
$ cat sample.csv
1, 2, 3
4, 5, 6
```

```bash
$ cut -d, -f1 sample.csv
1
4
```

### [uniq](https://www.ibm.com/docs/ja/aix/7.1?topic=u-uniq-command)

- 重複行を削除したり、重複行を抽出したりするときに利用する
- 重複は隣接している必要があるので、`sort`を噛ませることが多い
- `-d` (duplicated) で重複行を抽出する。`-u` (uniq) で重複行を削除する

### [grep](https://www.ibm.com/docs/ja/aix/7.1?topic=g-grep-command)

- ファイル内の文字列を検索するときに利用する
- `-v`で反転 (invert) することができる
- `-i`で大文字小文字を無視するこできる-とができる
- マッチした前後の行を表示できるマッチするには`-A` (after), `-B` (before), `-C` (context, A,B に同じ数字を入れる場合と同様) を利用する
- AND 検索はできないので、`grep "hoge" | grep "fuga"`のようにパイプで繋げる
- OR 検索は`grep -e "hoge" -e "fuga"`のように`-e`オプションを利用する
- 正規表現を利用する場合は`-E`を利用する

```bash
# hogeが含まれる行を前後1行表示
grep -A 1 -B 1 "hoge" sample.txt
```

圧縮ファイルを検索するときは、`zgrep`を利用する。

```bash
zgrep "hoge" sample.txt.gz
```

tail -f でログを監視するときは、`grep`で絞り込むと見やすくなる。

```bash
tail -f /var/log/messages | grep "error"
```

### sed

- 文字列の置換や削除を行うときに利用する (stream editor)
- `s/置換前/置換後/`のように記述する
  - vim で`:%s/置換前/置換後/g`とやるのは、%がファイル全体を表すから。g は全てのマッチを置換するという意味
  - 反対に行を選ぶ場合は`1,10s/置換前/置換後/g`のようにする
- `-i`でファイルを直接編集できる。上書きされるので基本つかわなくていい

### tail

- ファイルの末尾を表示するときに利用する
- `tail -n100` で末尾 100 行を表示する
- `-f`でファイルの末尾を監視できる。`tail -n 100 -f`で末尾 100 行を表示し続ける
- less のようにスクロールすることもできる。`tail -n 100 -f | less`で末尾 100 行を表示し続けるが、less の機能を使える
  - less と vim の違いは、less は読み込み専用で、vim は編集もできる
  - `tail -n100 | vim -` でファイルの末尾 100 行を vim で開くこともできる

### iconv

- 文字コードの変換を行うときに利用する
- `-f`で変換前の文字コード、`-t`で変換後の文字コードを指定する

```bash
# Shift_JISからUTF-8に変換
iconv -f SHIFT_JIS -t UTF-8 sample.txt
```

`tail -f`でログを監視するときに、文字化けしている場合に使うことがある。

```bash
tail -f logfile | while read LINE ; do echo $LINE | iconv -f SJIS -t UTF-8 ; done
```

### nkf (Network Kanji Filter)

- 文字コードの変換を行うときに利用する
- `-g` (guess) で文字コード自動判別 `nkf -g sample.txt`
- `-w` utf-8 に変換 `nkf -w sample.txt`
- sjis, euc-jp, utf-8 などに変換できる
- Download が必要なので、権限がない場合は使えない

### paste

- 複数のファイルを横に結合するときに利用する

### awk

- sed や cut, grep の上位互換
- いつか使いこなせるようになりたい

## 練習問題

### 問 1. 2 つの csv ファイルの第 3 列に共通する値を抽出する

2 つのファイルを比較して、それぞれのファイルの 3 列目に共通して存在する値をみつけてください。ただし同一ファイル内で値がかぶることはありません。

#### 例

```
# A.csv
1, 1, 1
2, 2, 2
3, 3, 3
```

```
# B.csv
4, 4, 4
5, 5, 2
6, 6, 6
```

答え

```
2
```

#### 回答

```bash
cut -d "," -f3 A.csv B.csv | sort | uniq -d
2
```

### 問 2. 特定の時間帯に発生した特定のエラーコードを含む行を抽出する

午後 12:00-17:00 の間に発生した `ERROR 500`を含むすべての行を抽出してください

#### 例

```
# logs.txt
2024-05-01 11:59:00 INFO 200 Success
2024-05-01 12:00:00 ERROR 500 Internal Server Error
2024-05-01 12:01:00 INFO 200 Success
2024-05-01 13:00:00 ERROR 500 Internal Server Error
2024-05-01 17:00:00 ERROR 500 Internal Server Error
2024-05-01 17:01:00 ERROR 500 Internal Server Error
2024-05-01 18:00:00 ERROR 500 Internal Server Error
```

#### 回答

```bash
awk '$2 >= "12:00:00" && $2 <= "17:00:00" && /ERROR 500/' logs.txt

2024-05-01 12:00:00 ERROR 500 Internal Server Error
2024-05-01 13:00:00 ERROR 500 Internal Server Error
2024-05-01 17:00:00 ERROR 500 Internal Server Error
```

### 問題 3: ログファイルから最新の「BEGIN」から「END」までのセクションを抽出してください

ログファイルには複数の処理が記録されており、各処理は "BEGIN" と "END" というキーワードで囲まれています。
このログファイルから最も最新の "BEGIN" から "END" までのセクションを見つけ出し、その間のすべての行を抽出してください。

#### 例

```
# logs.txt
INFO 2024-05-01 11:59:00 process started
BEGIN 2024-05-01 12:00:00 task 1 started
INFO 2024-05-01 12:01:00 processing
END 2024-05-01 12:02:00 task 1 completed
BEGIN 2024-05-01 13:00:00 task 2 started
INFO 2024-05-01 13:01:00 processing
INFO 2024-05-01 13:02:00 still processing
END 2024-05-01 13:03:00 task 2 completed
```

#### 回答

ログファイルを逆順にして、最初の 'BEGIN' と 'END' のセクションを抽出し、それを再度逆順に戻す。
flag=1 の時に print して、END がきたら exit する。

```bash
tac logs.txt | awk '/END/{flag=1} flag; /BEGIN/{print; exit}' | tac
```

### 問題 4 特定日付のログファイルからエラーを含むファイルを抽出

あなたは特定の命名規則が適用されたログファイルが保存されているディレクトリにアクセスできます。これらのファイルは {name}.{YYYY-mm-dd}.log という形式で命名されています。2024-04-30 の日付を持つファイルの中から、「ERROR」という文字列がファイルの中身に含まれているファイルの名前を全て出力するスクリプトを作成してください。

仮に error_report.2024-04-30.log と app_error.2024-04-30.log のファイルがログ内に "ERROR" という文字列を含む行を持っているとします。

```
system.2024-04-28.log
error_report.2024-04-30.log
network.2024-04-30.log
app_error.2024-04-30.log
```

#### 回答

```bash
grep -l 'ERROR' *.2024-04-30.log

```
