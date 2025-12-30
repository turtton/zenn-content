---
title: "Kotlinの非同期完全に理解した"
emoji: "💡"
type: "tech"
topics: ["kotlin", "async"]
published: false
---

# はじめに

この記事は、自身が3年ぐらいKotlinと向き合って生やした非同期まわりの理解を言語化しまとめたものです。(おかしな点があれば優しいマサカリをお待ちしております)

得に重要なsuspend関数とkotlinx.coroutinesの基本的な要素にのみ触れ、次のコードの意味を大体理解できるようになることを目指します。

```kotlin
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlin.time.Duration.Companion.seconds

suspend fun main() {
    val job = Job()
    val scope = CoroutineScope(Dispatchers.Default + job)
    scope.launch {
        hello()
    }

    job.join()
}

suspend fun hello() {
    delay(1.seconds)
    println("Hello,")
}
```

:::message
このコードは終了しません。手元で実行される場合は自分で終了させる必要があります。
勝手に終了する[playground版もあります](https://pl.kotl.in/05SkwPOlo)(違いはこれを最後まで読めば理解できるはず)
:::

# suspend関数

Kotlinの言語機能として提供されている`suspend`関数を語らずして非同期処理は語れません。大抵はkotlinx.coroutinesとセットで触れられますが、それはこのsuspend関数のシンプルさ故に単体での説明が難しいためです。
この関数を簡単に言うと、名前の通り**途中で一時停止できる関数**です。しかもスレッドは止めません。これをJVM上で効率的に実現するためだけに存在しています。
これについて原案が[公式のKEEP](https://github.com/Kotlin/KEEP/blob/master/proposals/coroutines.md#implementation-details)にまとめられているので、そこからかいつまんで説明していきます。
:::message
本家では当時検討されていたawait関数などが登場していますが、現在の使用感に合わせて一部変更を加えています。
:::
