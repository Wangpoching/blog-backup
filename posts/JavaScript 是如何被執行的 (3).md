---
title: JavaScript 是如何被執行的 (3)?
---

假設有一段 JavaScript 的程式碼是這樣子的：

```js
var a = 1
function fn(){
  console.log(a)
  var a = 5
  console.log(a)
  a++
  var a
  fn2()
  console.log(a)
  function fn2(){
    console.log(a)
    a = 20
    b = 100
  }
}
fn()
console.log(a)
a = 10
console.log(a)
console.log(b)
```

在第二題的時候提到了在進入一個 Execution Context (EC) 的時候，會進行變數的初始化，這個動作也叫做 Hoisting，想知道這一題會輸出甚麼需要對 Hoisting 的規則有更深入的了解。

## **Hoisting**

我們把 EC 分成 global 還有 functional 兩種，首先看 Global EC 的 Hoisting。

* Global EC

1. 函式先初始化
2. 將使用 var 語法的變數初始化為 undefined，如果變數已經被定義則略過
3. 由前到後遍歷

* Functional EC

1. arguments 初始化
2. 函式初始化，，如果變數已經被定義則取代掉原本的
3. 將使用 var 語法的變數初始化為 undefined，如果變數已經被定義則略過
4. 由前到後遍歷

## **模擬程式碼執行過程**

#### Global EC

首先由上而下尋找有沒有函式被定義。我們找到了名為 fn 的函式，所以目前 `globalEC.VO = {fn: xxx}`。

因為接下來已經沒有函式被定義了，所以由上而下尋找有沒有 var 語法。我們找到了 var a = 1，所以目前 `globalEC.VO = {fn: xxx, a: undefined}`。

最後創造 globalEC.scopeChain = [globalEC.VO]。

記得之前說過函式被執行的時候，Execution Context 的　scopeChain 會是**自己的　VO 加上函式被定義時的 Execution Context 的　scopeChain** 嗎？ 所以其實在 fn 被定義的時候，會有 `fn.scope = globalEC.scopeChain`　被記錄下來，這個資訊就是所謂的**函式被定義時的 Execution Context 的　scopeChain**。

編譯階段結束以後，開始執行。

1. var a = 1，使得 `globalEC.VO = {fn: xxx, a: 1}`。
2. fn()，所以進入 fn EC。

#### fn EC

首先定義函式傳入的參數，但因為沒有參數被傳入所以跳過。

再來由上而下尋找有沒有函式被定義。我們找到了名為 fn2 的函式，所以目前 `fnEC.VO = {fn2: xxx}`。

由上而下尋找有沒有 var 語法，第四行 var a = 5，所以目前 `fnEC.VO = {fn2: xxx, a: undefined}`。第七行 var = a，但是 fnEC.VO 
裡已經有定義變數 a ，因此略過。

最後 `fnEC.scopeChain = [fnEC.VO, ...fnEC.scope]`，也就是 `fnEC.scopeChain = [fnEC.VO, globalEC.VO]`。

別忘了設定 fn2 的 scope，`fn2.scope = fnEC.scopeChain`。

編譯階段結束以後，開始執行

1. console.log(a)，印出 undefined。
2. var a = 5，所以 `fnEC.VO = {fn2: xxx, a: 5}`。
3. console.log(a)，印出 5。
4. a++，所以 `fnEC.VO = {fn2: xxx, a: 6}`。
5. fn2()，進入 fn2EC。

#### fn2 EC

首先定義函式傳入的參數，但因為沒有參數被傳入所以跳過。

再來由上而下尋找有沒有函式被定義，沒有所以跳過。

由上而下尋找有沒有 var 語法，也沒有，所以 `fn2EC.VO = {}`。

最後創造 fn2 EC 的 scopeChain，`fn2EC.scopeChain = [fn2EC.VO, ...fn2EC.scope]`，也就是 `fn2EC.scopeChain = [fn2EC.VO, fnEC.VO, globalEC.VO]`。

編譯階段結束以後，開始執行

1. console.log(a)，在 fn2EC.VO 找不到 a，在 fnEC.VO 找到 a 了，所以印出 6。
2. a = 20，在 fn2EC.VO 找不到 a，在 fnEC.VO 找到 a 了，所以 `fnEC.VO = {fn2: xxx, a: 20}`
3. b = 100，在 fn2EC.VO 找不到 b，在 fnEC.VO 找不到 b，連 globalEC.VO 都找不到。最後只好在 globalEC.VO 裡新增變數 b，賦值為 20，所以 `globalEC.VO = {fn: xxx, a: 1, b: 100}`

fn2 EC 執行結束以後，回到了 fn EC。

#### fn EC

繼續執行

6. console.log(a)，印出 20。

fn2 EC 執行結束以後，回到了 global EC。

#### Global EC

繼續執行

3. console.log(a)，印出 1。
4. a = 10，`globalEC.VO = {fn: xxx, a: 10, b: 100}`。
5. console.log(a)，印出 10。
6. console.log(b)，印出 100。

global EC 執行結束以後，Call Stack 為空。

## **輸出結果**

```
undefined
5
6
20
1
10
100
```

## 系列文章
[JavaScript 是如何被執行的 (1)?](https://lidemy5thwbc.coderbridge.io/2021/08/13/javascript-runtime-1/)
[JavaScript 是如何被執行的 (2)?](https://lidemy5thwbc.coderbridge.io/2021/08/13/javascript-runtime-2/)