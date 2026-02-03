---
title: JavaScript 是如何被執行的 (2)?
---

假設現在有一個 Javascript 的程式碼，程式碼長的是這樣子的。

``` js
for(var i=0; i<5; i++) {
  console.log('i: ' + i)
  setTimeout(() => {
    console.log(i)
  }, i * 1000)
}
```

## **JavaScript 如何執行**

想要知道這個題目的結果，首先要知道 JavaScript 程式碼是如何被編譯以及執行的。

V8 引擎開始執行一段 Javascript 的時候，首先會創造一個 Global 的 Execution Context（ 執行環境 ）。執行環境裡面會初始化一些變數，產生 this 以及產生 ScopeChain，。

除了 Global Execution Context 以外，執行每個函式以前，V8 引擎也會先創造專屬於要執行的函式的 Execution Context，裡面一樣會初始化一些變數，this 以及產生 Scope Chain。

## **執行流程**

#### Global Execution Context

我們把這個 Global Execution Context 簡稱為 GlobalEC，在編譯階段先參考有沒有變數要先初始化，首先創造一個叫做 Variable Object(VO) 的物件，裡面存取 Global Execution Context 裡的變數以及變數的值。

因為還在編譯階段，所以我們只需要騰出記憶體空間來給變數就好，瀏覽過一遍程式碼以後，GlobalEC 的 VO 會長得像這樣：

```
globalEC.VO = {
  i: undefied
}

```

接著把 ScopeChain 給設定，Scope Chain 是一個陣列，裡面儲存了 Execution Context 的 VO，GlobalEC 的 ScopeC hain 會長得像這樣：

```
GlobalEC.scopeChain = [GlobalEC.VO]

```

編譯完成以後進入執行階段，把 for 分解一下：

```
i = 0
i < 5 // true
console.log('i: ' + i)
setTimeout(() => {
    console.log(i)
  }, i * 1000)
i = 1
i < 5 // true
console.log('i: ' + i)
setTimeout(() => {
    console.log(i)
  }, i * 1000)
i = 2
i < 5 // true
console.log('i: ' + i)
setTimeout(() => {
    console.log(i)
  }, i * 1000)
i = 3
i < 5 // true
console.log('i: ' + i)
setTimeout(() => {
    console.log(i)
  }, i * 1000)
i = 4
i < 5 // true
console.log('i: ' + i)
setTimeout(() => {
    console.log(i)
  }, i * 1000)
i = 5
i < 5 // false
break
```

接著開始逐行執行程式碼，`i = 0` ，i 要去哪裡找呢? 這個時候 Global Execution Context 的 Scope Chain 就派上用場了，變數會依序從 Scope Chain 裡儲存的物件裡尋找，還記得 `GlobalEC.scopeChain = [GlobalEC.VO]` 嗎? 也就是說 i 會在 GlobalEC.VO 裡尋找，所以

```
globalEC.VO = {
  i: 0
}
```

接著是 `i < 5`，一樣會用　GlobalEC.VO　裡的 i 進行判斷，所以判斷為 true。

接著是`console.log('i: ' + i)`，所以印出 `i: 0`。

接著是`setTimeout(() => {　console.log(i)　}, i * 1000)`，這邊要注意因為 setTimeout 是一個函式，所以現在會進到一個 setTimeout Execution Context，因為 setTimeout 可能執行很多次，所以姑且先叫做　setTimeout Execution Context I。

#### SetTimeOut Execution Context I

因為 setTimeOut 是內建函式，所以我們暫時把它當作一個黑盒子，但基本上流程還是這樣子的。

1. 初始化
2. 執行

初始化的過程一樣會創建 variable object。

```
setTimeOutEC_I.VO = {
  argument1: () => {　console.log(i)　}
  argument2: i * 1000 // 0 * 1000 = 0
}
```

這邊有個小問題是 argument2 的值 i 是甚麼，因為 SetTimeOut Execution Context I 還在編譯階段，所以這裡的 i 會是 globalEC.VO 裡的 i，也就是 0。 

接著便有趣了，初始化階段還要創造 Scope Chain，首先變數應該要從自己的執行環境先開始找起嘛，所以 SetTimeOutEC_I.scopeChain =
[SetTimeOutEC_I.VO]，那如果找不到呢? 接著要往**當前的函數被宣告的執行環境**去找。

setTimeOut 這個函式是在哪裡被定義的呢? 因為是內建函式，所以肯定在 Global EC 就宣告了，否則根本沒辦法從 Global Execution Context 進入到 SetTimeOut Execution Context I。

所以現在我們使得 `setTimeOutEC_I.scopeChain = [setTimeOutEC_I.VO,...globalEC_I.scopeChain]`，所以最後`setTimeOutEC_I.scopeChain = [setTimeOutEC_I.VO,globalEC_I.VO]`。

編譯完成進入執行階段，呼叫 Web API，這時候瀏覽器就會使用另一個 thread 來計時 0 秒，0 秒後將 callback function 丟進 Callback Queue。

SetTimeOut Execution Context I 執行完以後就會被移走，因為 Global Execution Context 還沒執行結束，所以不用再初始化，現在又回到了 Global Execution Context 裡。

#### Callback function

仔細觀察一下程式碼會發現接著還會再進入，SetTimeOut Execution Context II, SetTimeOut Execution Context III, SetTimeOut Execution Context VI。因為接下來的事情都很重複所以就不再詳細走過一遍。

在程式執行的時候，總共有五個計時器在運作，分別要計時，0 秒、 1 秒、 2 秒、 3 秒、 4 秒。要注意的是因為這五個計時器也是非同步運作的，所以最後執行 callback 的時間原則上都只會差一秒。

最後我們來模擬一下，callback function 是怎麼被執行的。

callback function 執行的順序應該是這樣的：

1.() => {console.log(i)} // 在 SetTimeOut EC I 時被定義
2.() => {console.log(i)} // 在 SetTimeOut EC II 時被定義
3.() => {console.log(i)} // 在 SetTimeOut EC III 時被定義
4.() => {console.log(i)} // 在 SetTimeOut EC VI 時被定義
5.() => {console.log(i)} // 在 SetTimeOut EC V 時被定義

因為這五個都是函式，所以會有五個執行環境被誕生，我們就叫他們 Callback EC I ~ Callback EC V。

從 Callback EC I 開始，因為函式裡面沒有任何東西被宣告，也沒有參數，所以 `callbackEC_I.VO = {}`。接著要創造 callbackEC_I.scopeChain，創造 scopeChain 的規則首先放入目前執行環境的 VO，所以 `callbackEC_I.scopeChain = [callbackEC_I.VO]`，接著要加上**函式被定義時的執行環境的 scopeChain**。 因為這個函式是在 Global Execution Context I 被定義的，所以 `callbackEC_I.scopeChain = [callbackEC_I.VO, ...globalEC.scopeChain]`，也就是 `callbackEC_I.scopeChain = [callbackEC_I.VO, globalEC.VO]`。

編譯完成以後開始執行 `console.log(i)`，循著 callbackEC_I.scopeChain 尋找變數 i，最後在 globalEC.VO 裡找到了 i = 5，所以印出 5。

#### 結果

結果會如何也是顯而易見了，最後印出的結果會是：

```
i: 0
i: 1
i: 2
i: 3
i: 4
5
5
5
5
5
```

最後可以參考 CallStack 的示意圖來對各個 Execution Context 生成及消失的時機更明瞭。

![img](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/ObxP0Kd.png)

## **系列文**
[JavaScipt 是如何被執行的 (1)](https://lidemy5thwbc.coderbridge.io/2021/08/13/javascript-runtime-2/)