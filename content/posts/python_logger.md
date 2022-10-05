---
title: "PythonのLogger"
date: 2022-10-06T00:02:06+09:00
description: "PythonのLoggerの使い方"
draft: false
tags: ["Python", "Library"]
categories: ["Python"]
---

## Loggerに関する覚書き

- logRecordが一行ずつのログのメッセージをもつクラスである。
- loggerがlogRecordを生成し、Handlerが出力する
- LoggerがHandlerを持ち、HandlerがFormatterを持つ
- rootLoggerに直接ログを生成させない
- nameを.で区切ることによって階層的な構造を持たせられる。子のloggerのログの重要度を一括で変更できる

## それぞれのモジュールはこのように書く (基本)

それぞれのファイルでloggerを生成し、loggerでhandlerやLevelを設定する

```python=
from logging import getLogger,StreamHandler,DEBUG
logger = getLogger(__name__)    #以降、このファイルでログが出たということがはっきりする。
handler = StreamHandler()
handler.setLevel(DEBUG)
logger.setLevel(DEBUG)
logger.addHandler(handler)
```

## メインのファイルでbasicConfigをいじる

一番上の階層のファイル (main) でloggingをいじって、出力設定を一括で管理する

```python=
if __name__ == '__main__'
    logging.basicConfig(level=logging.DEBUG,
                        format='%(asctime)s- %(name)s - %(levelname)s - %(message)s')
    logging.debug('this is debug message')
    logging.info('this is info message')
    logging.warning('this is warning message')
    logging.error('this is error message')
    logging.critical('this is critical message')
```

## 参考

- [pythonのロギングに関するメモ](http://joemphilips.com/post/python_logging/)
- [【Python】ロギングのベタープラクティス](https://qiita.com/ryoheiszk/items/362ae8ce344966b5516c)
  - ファイルごとにformetterやHandlerをいじるのは面倒なので、setLoggerなどの便利関数を作成しておいて、ファイルごとにこの関数を呼び出すことで一括で管理してしまう選択肢もある

### mylogger (例)

```python=
import logging
import logging.handlers


def set_logger(module_name):
    """ファイルごとに__name__でmodulenameを取得できる"""
    logger = logging.getLogger(module_name)
    logger.handlers.clear()

    streamHandler = logging.StreamHandler()
    # fileHandler = logging.handlers.RotatingFileHandler(
    #     "./test.log", maxBytes=10000, backupCount=5
    # )

    formatter = logging.Formatter(
        "%(asctime)s [%(levelname)s] (%(filename)s | %(funcName)s) %(message)s"
    )

    streamHandler.setFormatter(formatter)
    # fileHandler.setFormatter(formatter)

    logger.setLevel(logging.DEBUG)
    streamHandler.setLevel(logging.INFO)
    # fileHandler.setLevel(logging.DEBUG)

    logger.addHandler(streamHandler)
    # logger.addHandler(fileHandler)
    # logger.addHandler(emailHandler)

    return logger
```
