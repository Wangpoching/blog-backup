---
title: Virtual DOM 實作與原理解析
---

## 前言

現代前端框架的 Vue 以及 React 在試圖更新畫面的時候，並不會直接改變整個 DOM，因為這件事非常的耗費資源。事實上整個 DOM 會被 javascript 物件來模擬，這個物件被稱作 Virtual DOM。

透過比較新舊 Virtual DOM，可以得知那些節點需要被新增/刪除/修改，並批次更新真實 DOM 中的節點。

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/64651be75e243469.png)

從上面的示意圖中我們可以看到我們不需要產生整個新的 DOM，雖然我們需要生產一個新的 Virtual DOM 來與舊的 Virtual DOM 比較，不過經過比較最後我們只需要做一次 appendChild 來改變 DOM 即可。

用講的好像似懂非懂，那麼讓我們來手刻一個透過比較 Virtual DOM 來更新畫面的網頁吧!

## 先備知識

### DOM API

有鑑於更新畫面最後仍要要實際更新 DOM，因此操控 DOM 的 API 是肯定要知道的。

* **Document.createElement(tagName)**：依指定的標籤創建 HTML 元素。

```js
  // create a new div element
  const newDiv = document.createElement('div');
}
```

* **Document.createTextNode(text)**：創造一個文字節點。

 ```js
 // create a new text node
 const newtext = document.createTextNode('text');
```

* **ParentNode.appendChild(node)**：將一個節點加到指定父節點的子節點列表的最末端。如果將被插入的節點已經存在於當前的 DOM Tree，那麼它將從原先的位置移動到新的位置（不需要事先移除要移動的節點）。

```js
const div = document.createElement('div');
const p = deocument.createElement('p');
div.appendChild(p);
console.log(div.outerHTML); // '<div><p></p></div>'
```

* **Node.setAttribute(key, value)**：設置屬性值。如果屬性已經存在，則更新；否則加入新屬性。

```js
const div = document.createElement('div');
div.setAttribute('style','display: flex;')
console.log(div.outerHTML); // '<div style="display: flex;"></div>'
```

* **Node.removeAttribute(key)**：刪除屬性。

```js
const div = document.createElement('div');
div.setAttribute('style','display: flex;')
div.reomveAttribute('style')
console.log(div.outerHTML); // '<div></div>'
```

* **ChildNode.replaceWith(node/DOMString)**：替換節點父節點下的子節點。

```js
const parent = document.createElement('div');
const child = document.createElement('p');
parent.appendChild(child);
const span = document.createElement('span');

child.replaceWith(span);

console.log(parent.outerHTML);
// '<div><span></span></div>'
```

* **Node.remove()**：把 Element 從 DOM 樹中刪除。

```js
var el = document.querySelector('.main');
el.remove();
```

### ES6 Proxy

另一個讀者需要知道的先備知識是 ES6 才有的 Proxy，他被用來代理物件的行為。

在 JavaScript 中我們可以對物件進行許多操作，最簡單的是取值還有賦值。

```js
const obj = {
    name: 'Peter',
    hasPet: false,
}

// 取值
const { name } = obj;
console.log(name) // 'Peter'

//賦值
obj.hasPet = true
console.log(obj.hasPet) // true
```

如果我們想要監聽取值還有賦值的動作並且達成某些 sideEffect，便可以使用 Proxy。

```js
const obj = {};
const handler = {
  set: (obj, prop, value) => {
    obj[prop] = 2 ** value;
  },
  get: (obj, prop) => {
    return obj[prop] * 2;
  }
};

const p = new Proxy(target, handler);
p.x = 2; 
console.log(p.x); // 8
```

我們把 obj 加上了 set 以及 get 兩個 handler，首先可以看到 set 的三個參數 obj、prop 以及 value，它們分別代表了被代理的物件、賦值的屬性以及賦值的值。另外，set handler 並不需要有回傳值，因為它只是賦值並不是取值。

接著看到 get handler，兩個參數分別代表被代理的物件以及取值的屬性，值得注意的是 return 的值會成為取值出來的結果。

有了 Proxy 我們便可以在物件(資料)改變時，做額外的事情。在 Virtual DOM 的案例裡面聰明的讀者應該猜到了我們會試圖在 set handler 裡面做比對 Virtual DOM 以及更新 DOM 的工作。

## 開始實作

終於進入了實作，在這裡我們先上主程式~

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/48f71eadb2399e4f.png)

### createElement

主程式第 64 行在建立初始畫面的 Virtual DOM，createElement 這個函式會回傳一個物件模擬實際的 DOM。

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/357f9a72bc262848.png)

這個函式相對簡單，`tagName` 紀錄了 element 的種類、`attrs` 紀錄 element 的所有屬性、`children` 裡面也存了許多 createElement 產生的物件，代表目前這個 element 底下的子節點。

### render

在主程式第 65 行將 Virtual DOM 試圖轉換為真實的 DOM，用到的是 render 函式。這邊需要拆成兩個部分來看，一種是產生 Text 節點，其次是複雜的節點。

在主程式碼第 20 行的地方 `String('Current count: ${count}')` 便是 Text 節點的案例，首先看 render 如何處理 Text 節點。

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/6d96e957c556b824.png)

如果是複雜的節點則呼叫 renderElement，它會根據 tagName 產生一個新的節點，然後透過 setAttribute 把所有的屬性都設定上去。

如果有 children 便遞迴呼叫 render 遍歷所有的虛擬節點，產生相對應的元素，再用 appenChild 把所有的子節點都掛到 $el 上。

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/6fb4f6b3decade4f.png)

如果這個節點有好幾層，我們就會拿到一個很大的 DOM element，不過它還尚未被定位到 Document 上所以不會顯示在畫面上。

### mount

主程式第 66 行執行了 `mount 函式`，目的是將上一個步驟產生的 DOM element 掛到 Document 上，這個動作就稱為 mount。

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/35224c6430b89b63.png)

透過 replaceWith 我們將 DOM element 掛到 document.getElementById("app") 上，由於 app 是寫在 index.html 裡的元素，所以掛到 app 元素上便等於是掛到了 document 上。到這一個步驟網頁的畫面已經可以顯示出內容了!

### 建立 Proxy

接著要處理畫面的更新，在這個範例裡面透過更改 `{ count: number }` 的值，希望可以在 count 屬性的值變動時，在網頁上顯示出相應數量的圖片。

主程式的第 40 ~ 62 行便處理了這件事情，雖然前面已經貼過主程式但這裡還是再把 Proxy 的部分節錄說明。

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/8c0cc6f4a342780b.png)

Proxy 代理了 set 的動作，每當物件的屬性被重新賦值，就會觸發上圖第 12 ~ 15 行的動作，這些動作包含:

1. 根據 count 的值創建新的 virtual DOM
2. 比較舊的 Virtual DOM 與新的 Virtual DOM 的差異並回傳一個負責更新實際 DOM 的函式
3. 將舊的 DOM 丟進步驟 2 產生的函式完成 DOM 的更新

接下來我們將焦點轉移到如何比較 Virtual DOM。

### diff 演算法

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/b684c2a40fbd3070.png)

在比對 Virtual DOM 的時候，只會比對同一層的元素，不會進行交叉比對。我們把所有情況分為以下 4 種:

1. **傳入的新節點是 undefined**：代表該節點是將被刪除的節點，所以回傳的 patch 函式中會呼叫了 Node.remove() 來刪除該節點。
2. **舊節點或新節點的型態是字串**：則直接比較兩者，如果不一樣，則用新節點取代掉舊節點，否則不用改變。
3. **舊節點與新節點的標籤不一樣**：則用新節點 relaceWith 掉舊節點。
4. **舊節點與新節點的標籤一樣**：繼續往下比較標籤上的屬性以及子節點。

#### diffAttrs

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/93ceef50df5ff1ed.png)

在新舊節點的標籤一樣的狀況下首先要比對他們的屬性，diffAttr 會創建一個儲存 patch 的空陣列，接著遍歷新節點的屬性，產生包含 setAttribute 的 patch 並塞進陣列裡；接著遍歷舊節點的屬性，如果找到新節點沒有的屬性便將包含 removeAttribute 的 patch 塞進陣列裡。

最後回傳的 patch 會依序執行陣列裡面的所有 patch 來完成 attribute 的更新~

#### diffChildren

diffChildren 和 diffAttrs 一樣都是在新舊節點的標籤相同時使用，負責依序比對子節點並回傳 patch 函式。

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/091a94966ee99c83.png)

第 2 ~ 5 行負責遍歷舊節點的子節點，並一一與新節點的子節點用 diff 比對，注意到如果新節點的子節點比舊節點少，那麼 diff 的第二個參數會被傳進 undefined，所以會回傳一個包含 `$node.remove();` 的 node，如果對前面 diff 函式為甚麼要顧及到 vNewNode 為甚麼可能是 undefined 的情況有疑問的讀者可以再仔細想想。

第 7 ~ 13 行負責將新節點多出來的子節點 appendChild 到新的 DOM 上，所以先透過 array.slice 切出新節點相較於舊節點多出來的子節點，接著產生對應數量的 patch，這些 patch 會將子節點 render 出來並 appendChild。

16 ~ 20 行執行更新與刪除子節點的任務，值得一提的是這些任務是由 childPatches 的最末端的 patch 開始執行，讀者可以稍微思考一下這麼做的原因。


-----

-----

----- 

防雷線

-----

-----

-----


如果是由第一個 patch 開始執行，那麼 `const $child = $node.childNodes[i];` 這一行便可能噴錯，因為 patch 函式有可能將 node 底下的 childNode 移除，導致 i 大於剩餘的 childNode 數量呢!

## Recap

實作終於告一段落了，最後再回顧一次這一次實作的步驟。

* 初始化
1. 資料建立 Proxy
2. 根據資料的初始值建立 Virtual DOM
3. 將 Virtual DOM 轉成 DOM 元素
4. 將 DOM 元素 mount 到畫面上

* 當資料變化時，Proxy 產生如下的 sideEffect
1. 根據資料被更新的值建立 Virtual DOM
2. 比較新舊 Virtual DOM
3. 產生更新 DOM 的函式 (patch)
4. 執行 patch

實作的程式碼在[這裡](https://codesandbox.io/s/virtual-dom-proxy-api-forked-7676nn)，下一篇文章預計會介紹一個好用的 Redux middleware - Redux Saga。











