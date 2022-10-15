---
title: "Apollo Studioとローカル環境で立ち上げたGraphQL Expressサーバー間でCookieを使用する"
date: 2022-10-15T19:32:00+09:00
tags: ["typescript", "express"]
categories: ["typescript"]
draft: false
---

NodeJSでGraphQLバックエンドサーバーをapollo-serverとexpressを使用して立ち上げた際、Apollo StudioからGraphQLの確認を行うにあたり、Cookieの設定に数日悩んだので解決方法を共有します。
<!--more-->

行うことは以下の三点です。

## 1. CORSの設定

### Acceess-Control-Allow-OriginとAccess-Control-Allow-Credentialの設定をする


```typescript
  app.use(cors({
    origin: ["http://localhost:3000", "https://studio.apollographql.com"],
    credentials: true
  }))
```

## 2.プロキシの設定

apollo stuioのウェブサイトでhttps://localhost:4000/graphqlとの通信を行う際にプロキシで中継しているため、以下の二点を追加します。

### 2.1 expressサーバーに1回までproxyを信頼させる。


```
app.set("trust proxy", 1)
```

### 2.2 apollo studioからのリクエストのヘッダにX-Forwarded-Proto httpsを追加する。

プロキシとapollo studio間がHTTPS通信であることを知らせる。
![X-forwarded-proto](/img/634a9ad604bfcac0e454b030.png)


## 3. Cookieの設定を行う

SameSite Noneとsecure: trueを設定する。

```typescript
  app.use(
    session({
      name: COOKIE_NAME,
      store: new RedisStore({ client: redis, disableTouch: true }),
      cookie: {
        maxAge: 1000 * 60 * 60 * 24 * 365 * 10, // 10 years
        httpOnly: true,
        // sameSite: 'lax', //csrf
        // secure: __prod__,//cookie only works in https
        sameSite: "none",
        secure: true,
      },
      saveUninitialized: false,
      secret: "<some thing>"
      resave: false,
    })
  )
```
## 参考サイト
- [GraphQL, Apollo Studio, and Cookies](https://blog.devgenius.io/graphql-apollo-studio-and-cookies-5d8519d0ca7e)

## サーバーを立ち上げるコード

使用したコードは以下となります。


```typescript
import "reflect-metadata";
import { COOKIE_NAME, __prod__ } from "./constants";
import express from "express";
import { ApolloServer } from "apollo-server-express";
import { buildSchema } from "type-graphql";
import session from "express-session"
import connectRedis from "connect-redis";
import { MyContext } from "./types";
import Redis from "ioredis";
import AppDataSource from "./config/appDataSource";
import cors from "cors";

declare module "express-session" {
  interface SessionData {
    userId: number
  }
}


const main = async () => {
  await AppDataSource.initialize();

  const app = express();

  const RedisStore = connectRedis(session);
  const redis = new Redis();

  app.use(cors({
    origin: ["http://localhost:3000", "https://studio.apollographql.com"],
    credentials: true
  }))

  !__prod__ && app.set("trust proxy", 1);

  app.use(
    session({
      name: COOKIE_NAME,
      store: new RedisStore({ client: redis, disableTouch: true }),
      cookie: {
        maxAge: 1000 * 60 * 60 * 24 * 365 * 10, // 10 years
        httpOnly: true,
        // sameSite: 'lax', //csrf
        // secure: __prod__,//cookie only works in https
        sameSite: "none",
        secure: true,
      },
      saveUninitialized: false,
      secret: "<some thing>"
      resave: false,
    })
  )


  const appoloServer = new ApolloServer({
    schema: await buildSchema({
      resolvers: [],
      validate: false
    }),
    context: ({ req, res }): MyContext => ({ req, res, redis }),
  });

  await appoloServer.start();
  appoloServer.applyMiddleware({
    app,
    cors: false,
    path: '/graphql'
  });
  app.listen(4000, () => {
    console.log("server started on localhost:4000");
  });
};

main().catch(err => {
  console.log(err);
});
```


