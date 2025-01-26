---
title: "cdk (TypeScript) とLambda (Java) でHelloWorldする"
author: ["えじっさ"]
date: 2024-12-19T23:19:34+09:00
tags: ["aws", "typescript", "java", "cdk"]
images:
  - "img/og/20241219_cdk_javaLambda_HelloWorld.png"
categories: ["aws", "cdk", "java"]
draft: false
---

## 概要

AWS のリソースをアプリケーションコードから作成するのに AWS CDK はとても便利です。
CDK の実装が溜まってくると、過去のプロジェクトからコードをコピーして持ってくればコンソールを触ることなく似たインフラ構成を立ち上げることができます。

最近 Java で実装した Lambda を CDK で管理しようとしたところ、試行錯誤したので記録を残しておこうと思います。

ポイントは以下となります。

- gradle でビルドするときは, fat Jar が必要。`com.github.johnrengelman.shadow`を入れて, `./gradlew shadowJar`で Jar を作成する
- ビルドさせるときにデフォルトだと権限のない/root/.gradle を参照しようとするので`GRADLE_USER_HOME`を編集する
- メモリを 128MB, 256MB だと初回起動に時間がかかってタイムアウトしてしまうので、十分にメモリ確保するかタイムアウト時間を伸ばす

## Lambda 用 construct

construct は次のように生成しています。
`rm -rf build/libs`は IDE 側で`./gradlew build`すると普通の Jar が生成されてしまいます。そのため、ビルド前に消して Fat Jar のほうをアップロードされるようにしています。

`GRADLE_USER_HOME`の指定がないと次のエラーが出てビルドに失敗します。

> Exception in thread "main" java.lang.RuntimeException: Could not create parent directory for lock file /.gradle/wrapper/dists/gradle-8.4-bin/1w5dpkrfk8irigvoxmyhowfim/gradle-8.4-bin.zip.lck

Lambda の Java のプロジェクトは software/HelloWorldFunction に入っています。

```=typescript
// api-gatewayのリクエストを分割してDynamoDBに保存するLambda関数
export class ReqBroker extends Construct {
  constructor(scope: Construct, id: string) {
    super(scope, id);

    // root/.gradleを利用しないように, GRADLE_USER_HOMEを設定
    // permission deniedエラー回避
    // Exception in thread "main" java.lang.RuntimeException: Could not create parent directory for lock file /.gradle/wrapper/dists/gradle-8.4-bin/1w5dpkrfk8irigvoxmyhowfim/gradle-8.4-bin.zip.lck
    const bundlingAssets = lambda.Code.fromAsset(
      join(__dirname, "../../software", "HelloWorldFunction"), {
      bundling: {
        image: lambda.Runtime.JAVA_21.bundlingImage,
        bundlingFileAccess: cdk.BundlingFileAccess.VOLUME_COPY,
        command: [
          "bash", "-c",
          [
            "rm -rf build/libs",
            "export GRADLE_USER_HOME=/asset-input/.gradle",
            "./gradlew shadowJar",
            "cp build/libs/*.jar /asset-output/",
          ].join(" && "),
        ],
      }
    })

    // JVMの起動に多少のメモリが必要
    // 128MB, 256MBだと起動に時間がかかるので, timeoutを10sに設定
    new lambda.Function(this, "ReqBroker", {
      runtime: lambda.Runtime.JAVA_21,
      handler: "helloworld.App::handleRequest",
      memorySize: 256,
      timeout: cdk.Duration.seconds(10),
      code: bundlingAssets,
    })
  }
}
```

## Lambda の Java コード

inteliJ IDE の SAM Project のテンプレートをそのまま流用しました。

```=java

/**
 * Handler for requests to Lambda function.
 */
public class App implements RequestHandler<APIGatewayProxyRequestEvent, APIGatewayProxyResponseEvent> {

    public APIGatewayProxyResponseEvent handleRequest(final APIGatewayProxyRequestEvent input, final Context context) {
        Map<String, String> headers = new HashMap<>();
        headers.put("Content-Type", "application/json");
        headers.put("X-Custom-Header", "application/json");

        APIGatewayProxyResponseEvent response = new APIGatewayProxyResponseEvent()
                .withHeaders(headers);
        try {
            final String pageContents = this.getPageContents("https://checkip.amazonaws.com");
            String output = String.format("{ \"message\": \"hello world\", \"location\": \"%s\" }", pageContents);

            return response
                    .withStatusCode(200)
                    .withBody(output);
        } catch (IOException e) {
            return response
                    .withBody("{}")
                    .withStatusCode(500);
        }
    }

    private String getPageContents(String address) throws IOException{
        URL url = new URL(address);
        try(BufferedReader br = new BufferedReader(new InputStreamReader(url.openStream()))) {
            return br.lines().collect(Collectors.joining(System.lineSeparator()));
        }
    }
}

```

## Lambda の実行結果

起動成功しました。256MB の場合初回の起動は 5000ms かかり、その後は 80ms 程度でレスポンスが帰ってきました。
メモリを増やせば初回起動にかかる時間は短縮できます。

```
{
  "statusCode": 200,
  "headers": {
    "X-Custom-Header": "application/json",
    "Content-Type": "application/json"
  },
  "body": "{ \"message\": \"hello world\", \"location\": \"3.113.215.251\" }"
}
```

## 感想

Java で実装した Lambda を CDK でデプロイする参考資料が少なく苦戦しました。
うまく起動できて良かったです。

参考として、[レポジトリ](https://github.com/edge2992/lambdaBroker/tree/helloWorldLambda)を公開しました。
詳細を知りたい方はこちらも参考にしてください。
