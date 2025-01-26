---
title: "React v18 + NextjsでのHydration failedの回避"
date: 2022-10-14T00:05:18+09:00
description: "React v18 + NextjsでのHydration failedの回避"
tags: ["typescript", "nextjs"]
categories: ["typescript"]
draft: false
---

Nextjsを使用して、SSR対応のサイトを作成していたところエラーが発生するようになった。
SSRとクライアントレンダリングの間で、HTML構造に違いがありました。

<!--more-->

## エラー内容

```
Error: Hydration failed because the initial UI does not match what was rendered on the server.

See more info here: https://nextjs.org/docs/messages/react-hydration-error
```

```
next-dev.js?3515:20 Warning: An error occurred during hydration. The server HTML was replaced with client content in <div>.

See more info here: https://nextjs.org/docs/messages/react-hydration-error
```

## 原因

原因は, サーバーでのレンダリングとクライアントでのレンダリングでHTML構造に差が生じていることでした。

### 該当箇所

NavBarで、body変数内のレンダリングを変更させているところでエラーが出ていた。

```typescript
import { Box, Button, Flex, Link } from "@chakra-ui/react";
import React from "react";
import NextLink from "next/link";
import { useLogoutMutation, useMeQuery } from "../generated/graphql";
import { isServer } from "../utils/isServer";

interface NavBarProps {}

export const NavBar: React.FC<NavBarProps> = ({}) => {
  const [{fetching: logoutFetching}, logout] = useLogoutMutation();
  const [{ data, fetching }] = useMeQuery({
    pause: isServer(),
  });


  let body = null;
  // data is loading
  if (fetching) {
    // user not logged in
  } else if (!data?.me) {
    body = (
      <>
        <NextLink href="/login">
          <Link mr={2}>login</Link>
        </NextLink>
        <NextLink href="/register">
          <Link mr={2}>register</Link>
        </NextLink>
      </>
    );
    // user is logged in
  } else {
    body = (
      <Flex>
        <Box mr={2}>{data.me.username}</Box>
        <Button
          onClick={() => {
            logout(undefined);
          }}
          isLoading={logoutFetching}
          variant="link"
        >
          logout
        </Button>
      </Flex>
    );
  }

  return (
    <Flex bg="tan" p={4}>
      <Box ml={"auto"}>{body}</Box>
    </Flex>
  );
};
```

## 対策 (本質的でない)

navBarのコンポーネントを使用する場所で、
[dynamic import](https://nextjs.org/docs/advanced-features/dynamic-import#with-no-ssr)
を使用してnavBarコンポーネントのサーバーでのレンダリングを回避する。

```typescript
import dynamic from "next/dynamic";
import React from "react";
import { Wrapper, WrapperVariant } from "./Wrapper";

interface LayoutProps {
  children: React.ReactNode;
  variant?: WrapperVariant;
}

const AvoidSSRNavBar = dynamic(() => import("./NavBar").then(modules => modules.NavBar), {ssr: false});

export const Layout: React.FC<LayoutProps> = ({ children, variant }) => {
  return (
    <>
    <AvoidSSRNavBar />
      {/* <NavBar /> */}
      <Wrapper variant={variant}>{children}</Wrapper>
    </>
  );
};
```
