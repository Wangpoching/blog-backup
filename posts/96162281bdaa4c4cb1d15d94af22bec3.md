---
title: JavaScript 是如何被執行的 (1)?
---

這一系列的文章會有四個範例，由淺入深的慢慢把 JavaScript 在瀏覽器上是如何被執行的給說清楚。

假設現在有一個 Javascript 的程式碼想利用 chrome 的 V8 引擎來執行，程式碼長的是這樣子的。

``` js
console.log(1)
setTimeout(() => {
  console.log(2)
}, 0)
console.log(3)
setTimeout(() => {
  console.log(4)
}, 0)
console.log(5)
```

首先先概略的了解一下瀏覽器會怎麼去分配不同的執行緒。V8 引擎是跑在 main thread 上的，順帶一提，網頁的畫面渲染也是 main thread 在負責的。那麼還有其他的 threads 會被分配去執行其他的工作，比如說負責按碼表計時的 thread。底下是基本的架構圖。

![img](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/6U1YFzT.png)

## **模擬各個 thread 的工作流程**

#### main thread

當程式碼開始執行，我們首先先關注 main thread 裡依序發生了甚麼事，注意一個 thread 一次只能做一件事，所以下面列舉的依照先後順序發生。把 Call Stack 想像成一種資料結構，Call Stack 決定了 main thread 要執行的任務的優先順序。

1. `console.log(1)` 印出 1。
2. `setTimeout(() => { console.log(2) }, 0)` 幫我設個計時器，0 秒之後執行 callback function
3. `console.log(3)` 印出 3。
4. `setTimeout(() => { console.log(4) }, 0)` 幫我設個計時器，0 秒之後執行 callback function
5. `console.log(5)` 印出 5。

到此為止程式碼被執行完畢。

#### timeout thread 1

假設我們把負責計時的 thread 叫做 timeout thread 好了，第一次 main thread 想要叫 timeout thread 計時 0 秒，所以編號 1 的 timeout thread 就計時 0 秒，接著把 callback 函式丟到 Callback Queue 裡面去。

#### timeout thread 2

第二次 main thread 又想要叫 timeout thread 計時 0 秒，所以編號 2 的 timeout thread 就計時 0 秒，接著把 callback 函式丟到 Callback Queue 裡面去。

#### Callback Queue

我們把 Callback Queue 以一個陣列表示，裏頭有兩個匿名函式，`[() => { console.log(2) }, () => { console.log(4) }]`。

#### Event Loop 

Event Loop 遵守幾個原則。

* 不斷檢查 main thread 有沒有任務。
* 如果 main thread 沒有任務，告知 main thread 處理 Callback Queue 的第一個任務，然後把這個任務從 Callback Queue 刪掉。

接著來模擬一下 Event Loop 的執行步驟吧。

1. 一直盯著 main thread，直到 main thread 執行完步驟 5，這時候 main thread 是沒有任務的。
2. 把 () => { console.log(2) } 交給 main thread 執行。
3. 一直盯著 main thread，直到 main thread 沒有任務。
4. 把 () => { console.log(4) } 交給 main thread 執行，這時 Callback Queue 空了。

#### main thread

我們再回到 main thread 一次，從步驟 6 開始。

6. 執行 Event Loop 請求的 `() => { console.log(2) }`，印出 2。
7. 執行 Event Loop 請求的 `() => { console.log(4) }`，印出 4。

到此為止再用一張流程圖來視覺化上面的流程。

![img](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/wmlMtXT.png)

#### 結果

最後結果會輸出：

```
1
3
5
2
4
```