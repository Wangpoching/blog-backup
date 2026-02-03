---
title: 巢狀救星三部曲(1) - 從 Callback Hell 到 Promise Chain
---

## 前言

在 JavaScript 裡頭，同步以及非同步的概念在社群的努力下應該很容易可以管道來了解，所以這系列文章會跳過這一部分來談談在非同步的程式碼中常常碰到的問題 - **巢狀地獄**（ Callback Hell ），在這系列的三篇文章中我們將一次次升級手段來解決巢狀地獄!

## 巢狀地域

首先要先了解這系列文章想要解決的問題，下面的程式碼模擬了一個 request，使用者可以輸入兩個 Callback function，一個會在 200 response 觸發，另一個會在 500 response 觸發。

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/071f695e392cd44a.png)

現在我們模擬一個情境，假設有一個 twitch hot 的網站會顯示前 100 名最夯的頻道，如果 Twitch 的 API 一次只提供 20 筆資料，因為後端的資料庫是 [cursor-based](https://tec.xenby.com/36-%E9%BE%90%E5%A4%A7%E8%B3%87%E6%96%99%E5%BA%AB%E5%88%86%E9%A0%81%E6%96%B9%E6%A1%88-cursor-based-pagination) 的緣故，後面要再拿到 20 筆資料需要帶上前一個 request 返回的 token。

在這樣的情況下，我們必須等到第一個 request 收到 response 以後再發第一個 request...

我們可以模擬一下用 Callback function 的寫法：
![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/d3570a8fdc222e0e.png)

筆者在打這段程式碼的時候差點被 indentation 搞瘋，如果我們要寫更多層巢狀的話直接按 tab 鑑按到手殘廢，況且在 ESLint 裡面甚至有每行長度限制的選項存在，也就是說巢狀語法是公認的糟糕呀!

題外話，論藝術感來說，巢狀語法的形狀其實滿有型的，下面附上幾張經典圖 XDD

* 金字塔
![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/a95d7dc23c81914a.png)
* 來一發特大波動拳ㄚㄚㄚㄚ 
![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/de19af2d06919687.jpg)


## Promise

大家的哀嚎 ECMAScript 都聽到了， ES6 的 Promise 物件 **Come to your rescue**!

### 基本語法

Promise 應該被大家用到爛掉了，但筆者還是非常快的將它的基本寫法給過水一下。

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/99524d6c14b077a3.png)

創建 Promise 物件時填入一個函式來寫要做的事情，比如說 Call API 之類非同步的事情，當然也可以寫同步的程式碼，總之在 Promise 物件被創建起來的時候，裡面的 Code 就會被執行。

填入的這個函式會收到兩個函式作為參數，當第一個函式被呼叫代表狀態成功，當第二個函式被呼叫代表狀態失敗。

這是一個什麼樣的概念呢? 讓我用狀態機來解釋~

### 有限狀態機

有限狀態機表示有限個狀態以及在這些狀態之間轉移的數學模型，請注意「有限」以及「狀態」。

* 有限狀態：拿國小生作為例子，一個國小生可能是一到六年級的其中一個狀態，這就是有限狀態。
同樣的，Promise 物件也有狀態，分別有 Pending（ 等待中 ）、 Fullfilled（ 成功 ）、Rejected（ 失敗 ） 三種狀態。
* 初始狀態： 狀態機肯定有一個初始狀態，小學生的初始狀態是一年級，而 Promise 的初始狀態是 Pending。
* 狀態轉換： 狀態間的轉換可能會有限制，以小學生來說，狀態只能持平或往上，而 Promise 只會從 Pending 變成 Resolve 或 Reject 的最終狀態。

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/2ae0ee2152e59bea.png)

### Chaining

有用過 jQuery 的人應該知道 Chaining 的厲害之處，像是下面這樣的範例。

`$("#p1").css("color", "red").slideUp(2000).slideDown(2000);`

jQuery 的物件可以用一個 statement 便完成許多事情的原因是因為它的每個函式最後都後將 jQuey 的物件回傳回來~ 而 Promise 物件也有類似的設計唷! 一起來看看把前面的 twitch request 波動拳改成 promise 的寫法!

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/0c5efd7eed25986e.png)

波動拳完全消失了呢! 這就是 promise 的物件方法 then 的厲害之處了，then 的參數是一個函式，會接收到 promise resolve 之後的值，而 return 的值可以再被下一個 then 給接收（注意: return 不一定只可以回傳 promise 物件）。

由於採用了 Chaining 的語法，所以大大改善了回呼函式不易閱讀的缺點!

### 補充

既然談到 Promise，筆者想再介紹兩個十分好用的 Promise 建構子的方法。

**Promise.all()**

如果 request 之間並不用互相等待依賴結果，希望可以同時並行可行嗎? 這時候請使用 `Promise.All`，把所有的 promise 都放進一個陣列再丟進來，等待所有 promise 都執行完畢便可以一次收到所有結果~

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/14306be6591bb57c.png)

注意: 
(1) 當 promise 被創建時，裡面如果有非同步的程式碼即開始執行，並非丟進 Promise.all 才開始執行!
(2) Promise.all 在 then 接收到的結果順序與傳入的順序一致，並不是先執行結束的在前面

**Promise.race()**

`所有的 Promise 誰先 resolve 誰就獲勝`，這是甚麼東西? 有甚麼情況會需要所有 Promise 比速度。讀者有想到甚麼情境嗎?

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/37ce3de894aa5720.png)

原來可以限制 request 逾時的時間呢! 這個方法很棒吧~

到此為止我們初步解決了非同步的巢狀地獄，不過還沒結束呢! 下一篇二部曲我們來瞧瞧 `ES6 Generators` 的厲害，敬請期待。









