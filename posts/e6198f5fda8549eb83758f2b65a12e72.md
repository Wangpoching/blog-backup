---
title: 巢狀救星三部曲(2) - ES6 Generator Function
---


這一篇要講的是 `ES6 Generator Function`，有點小複雜，但是是為了最後的 async/await 做鋪墊，async/await 相信很多讀者都用的得心應手了，從 Generator Function 開始打基礎可以讓我們了解 async/await 的運作機制，發出「喔~ 原來是這樣!」的讚嘆。
以下正文開始。

## 迭代器工廠

寫過 python 的人肯定對迭代器不陌生! generator function 是一個所謂的`迭代器產生工廠`，呼叫它就可以得到一個迭代器。

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/88d490d4918b41ad.png)

想要寫一個迭代器工廠必須`在函式前面加上 * 號`，當要生產一個迭代器時只要簡單的呼叫工廠即可。至於迭代器工廠裡面的 yield 是甚麼我們後面再談。

## 使用迭代器

當創建好了迭代器以後接著便可以使用它了，下面是它的使用方法。

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/b23544a8990b844b.png)

聰明的讀者應該發現到每迭代一次都會返回 yield 後面的值，至於 done 的值是 true 或是 false 則取決於是否已經執行到了最後 yield。

等等! 但是當 yield 到 3 的時候應該就要將 done 的值設成 false 了才對，為甚麼仍然要再 next 一次才會是 false 呢?

這就是迭代器的特性啦!! 迭代器是非常懶惰的，每執行一次 next 迭代器只會推進到下一個 yield 的所在，所以雖然讀者知道 `yield 3` 已經是最後一個 yield 了，但非常抱歉你的迭代器不知道 QQ

至於要如何解決這個問題，請把最後一個 `yield` 替換成 `return`，如此一來迭代器看到 return 便知道要結束了!

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/0042eaa431fab0de.png)

請讀者思考上面的程式碼會 console 出甚麼結果~

## Push-Pull Model

如果 ES6 Generator 這麼簡單就太可惜了。我們來看看它的推拉機制（Push-Pull Model）。

請讀者先看下面的範例。

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/92767570d33dd91d.png)

原來 next 裡面可以填值，不過 next 裡面的參數的效果是甚麼呢? 上圖程式碼的輸出結果會是:

```
{value: 0, done: false}
{value: 5, done: false}
{value: 11, done: false}
```
-----
現在讓我們來一窺 generator function 的詳細運作流程~

**accumulateIterator.next(4)**
第一次呼叫 next 填入參數 4，以下是運作流程：
(1) 迭代器開始執行，迭代器想要將上一個執行到的 yield 關鍵字的位置改成 4，但是因為是第一次迭代，沒有上一個 yield，只好往下執行。
(2) `total = defaultValue` defaultValue 預設為 0，所以 total 是 0
(3) 進入 while 迴圈，`total += yield total`，此時先執行等號右邊，遇到 yield 所以將 yield 右側的值輸出，因此第一個輸出的值是 0。

**accumulateIterator.next(5)**
第二次呼叫 next 填入參數 5：
(1) `total += yield total` 迭代器想要將上一個執行到的 yield 關鍵字的位置改成 5，所以目前 total 的值是 0 + 5 = 5。
(2) 繼續執行到 while 底部重新遇到 `total += yield total`。
(3) 此時遇到 yield，所以輸出 total，值是 5。


**accumulateIterator(6)**
第三次呼叫 next 填入參數 6：
(1) `total += yield total` 迭代器想要將上一個執行到的 yield 關鍵字的位置改成 6，所以目前 total 的值是 5 + 6 = 11。
(2) 繼續執行到 while 底部重新遇到 `total += yield total`。
(3) 此時遇到 yield，所以輸出 total，值是 11。

-----

到此為止讀者應該了解 Generator Function 的詳細運作了，這邊幫讀者畫兩個重點：
* 迭代器呼叫第一次的 next 方法，並且執行到第一次 yield 的位置時，會將 yield 旁邊的值輸出。
* 迭代器在第 n 次呼叫 next 方法並且代入任何值，該值就會取代前一個 yield 關鍵字的位置。

## Generator Function 的優點

普通的迭代器是靜態的，但是在 ES6 Generator Function 裡面是**可以動態的把值給 push 進去**的。至於每次呼叫 next 拿到 yield 右側的值的這個動作就叫做 pull，這也就是 Push-Pull Model 名稱的由來。

除了可以依照情況更改輸出狀態以外，迭代器最大的優點就是`惰性求值`。在上面的範例我們可以完全不用害怕寫無窮迴圈，但如果在一般的函式寫寫看，包準你的 callstack 馬上滿到溢出來。

惰性求值可以讓我們不用創造一個陣列來儲存非常多的值，而我們又可以確保得到每一個值。

基本上除了 Generator Function 有惰性求值的特性以外，其餘的表達式都是`積極求值`。
比如說 `let c = 3` 會立刻將 3 指派到變數 c 身上。
比如說 `3 + 5` 會立即運算出 8。

## 補充 - 費波那契數列

因為 Generator Function 擁有惰性求值的概念，所以很適合拿來寫費波那契數列並取得數列中任意的值，我們並不需要在一開始就求出費波那契數列的所有值並儲存在陣列裡。

讀者可以試著寫寫看，答案在防雷線後面。


-----

我是防雷線
 
我是防雷線
 
我是防雷線
 
我是防雷線
 
我是防雷線

-----

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/a032cdca3d2ceaa2.png)

Generator Function 跟優化非同步 callback function 的寫法到底有甚麼關係呀... 別擔心，下一篇是巢狀救星三部曲的最終章，會展示由 Generator Function 演化出的 async/await 語法如何徹底將 callback hell 給 K.O.



