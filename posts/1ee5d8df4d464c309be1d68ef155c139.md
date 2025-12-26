---
title: 巢狀救星三部曲(3) Async Functions
---

終於到了這個系列的最後一個篇章了! 今天要來介紹 Async Function，各位讀者有把前兩天的 Promise 以及 Generator Function 學好嗎?

## Promise Chain 寫成 Generator Function

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/1ffd87096b460c97.png)

還記得 Promise Chain 嗎? 如果想把上面的 Promise Chain 改寫成像下面這樣的 Generator Function。

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/a485903ba5decb01.png)

我就問! 如果想要把下面這個 Generator Function 跑起來並可以達到上圖 Promise Chain 的效果，你會怎麼做?

## 把 Generator Function 跑起來

讓我們思考一下，首先一定要建立一個迭代器，接著我們可以開始跑迭代器，因為我們會在**第一個 next 的 value 拿到第一個 Promise**，問題是接下來要如何把 Promise resolve 的值給賦值到變數 Response 上呢?

`const response1 = yield sendRequest()`

聰明的讀者想到了嗎? 我們可以利用 Promise 的 **then 在取得結果以後再將結果當作下一輪 next 的參數**!

像是這樣子的寫法:

```js
iterator.next().value.then(response1 => {
    // 將 response1 放進 next 當作參數
    iterator.next(response1)
})
```

如果還是不清楚這個想法的讀者，可以看第二個篇章介紹到的在 next 代入的參數會取代上一個 yield 的位置，也就是說**變數 response1 在上面的範例裡會被 sendRequest 產生的 promise resolve 出來的結果給賦值**。

## 再次出現的 Callback Hell

如果我們想要把整個 Generator Function 用 next 的方式得到所有 promise 的 resolve 結果，先請讀者想像一下會發生甚麼事。

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/799406e78d02fc7f.png)

哭阿! 又跟龍見面啦!

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/595fd041c8a65ffd.jpg)

龍再度支援收銀...

## 將 callback hell 寫成遞迴

既然我們做的事情只是不斷的呼叫 next，並且把上一個 next 回傳的 promise resolve 出來的結果給當作參數，何不寫成遞迴呢?

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/a9fa267f70af00c4.png)

這樣一來我們在外觀上只要寫一個 Generator，以及一個產生 iterator 並遞迴跑這個 iterator 的函式即可。Callback Hell 瞬間消失!

除此之外，我們甚至可以在 Generator Function 裡面寫 try catch 的邏輯。

為甚麼可以自由的寫 try catch 的語法，讀者可以自行思考一下，這邊筆者列出幾個想法:

1. Promise Chain 把非同步運作的邏輯強硬的串接，錯誤處理必須要被隔離到 .catch
2. Generator Function 可以把每個 promise 給獨立拆開，依賴的是 **Generator 的惰性執行**，可以完美的達成等待上一個 promise resolve 並接收值的效果

細心的讀者發現了嗎? 在 Generator Function 裡面，我們**把非同步的程式碼寫的像是同步的程式碼一樣**!!

## ES6 Async Function

筆者就不賣關子了，Async Function 做的事情很簡單，就只是：
1. 把 Generator Function 改成 Async Function
2. 把 yield 改成 await

不同的地方在於，Generator 必須要遞迴迭代，但是 Async Function 已經將把這個步驟封裝起來了！

這就是為甚麼 yield 關鍵字為甚麼會變成 await 的原因了!

最後筆者把上面的範例寫成 Async Function 做個結尾。

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/71d75eb974762264.png)

**鋪陳了三篇文章，終於引出了 Async Function 的運作機制! 完成優化非同步程式碼的最後一塊拼圖 謝謝收看~**






