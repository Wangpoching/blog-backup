---
title: JavaScript 是如何被執行的 (4)?
---

假設有一段 JavaScript 的程式碼是這樣子的：

```js
const obj = {
  value: 1,
  hello: function() {
    console.log(this.value)
  },
  inner: {
    value: 2,
    hello: function() {
      console.log(this.value)
    }
  }
}
  
const obj2 = obj.inner
const hello = obj.inner.hello
obj.inner.hello() // ??
obj2.hello() // ??
hello() // ??
```

這一次我們不討論 JavaScript 的執行過程，我們要討論 `this` 這個東西，程式碼執行到最後三行的時候會印出三次 this.value，所以這三個 this.value 會是甚麼呢?

## **this 如何被決定**

在之前變數可以被取用的範圍取決於語彙環境 (Lexical Environment)，也就是說是取決於`你把這段程式碼寫在哪`，再白話一點就是 Scope 是取決於函式在哪裡被定義的。而不是在哪裡被執行的。

但是，this 正好相反，它取決於`函式在哪裡被執行`。其實 `this` 這樣子的取名很傳神，給人一種**就是現在這個東西**的感覺。

## **實際結果**

`obj.inner.hello()` 的 this.value 是甚麼呢? 其實可以翻譯成**印出 obj.inner 的 value 來**，因為現在執行的是 obj.inner 上的 hello 函式，所以 this 這時候指向 obj.inner，所以會印出 2。

接著關注這段程式碼

```js
const obj2 = obj.inner
obj2.hello() // ??
```

因為 obj2 也指向 obj.inner 儲存的地方，所以 obj2.value 也是 2。當執行 obj2.hello()，可以翻譯成**印出 obj2 的 value 來**，所以會印出 2。

最後關注這段程式碼

```js
const hello = obj.inner.hello
hello() // ??
```

hello() 現在就單純只是一個函式，所以 this 指不到任何東西，在程式一開始執行時，會創造一個全域物件，這個時候的 this 會指向這個全域物件，在瀏覽器裡這個全域物件就是 Window，但是因為 Window 裡並沒有 value 這個屬性，所以會印出 undefined。

總結一下最後的輸出是

```
2
2
undefined
```

## 系列文章

[JavaScript 是如何被執行的 (1)?](https://lidemy5thwbc.coderbridge.io/2021/08/13/javascript-runtime-1/)
[JavaScript 是如何被執行的 (2)?](https://lidemy5thwbc.coderbridge.io/2021/08/13/javascript-runtime-2/)
[JavaScript 是如何被執行的 (3)?](https://lidemy5thwbc.coderbridge.io/2021/08/13/javascript-runtime-3/)
