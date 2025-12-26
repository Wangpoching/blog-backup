---
title: React-router-dom 實作與原理解析
---

## 前言

相信大家熟悉基本的 React 使用以後，如果想要進階肯定會學習 `Redux` 以及 `React Router` 吧! 其中透過 React Router 可以很容易的實現 SPA(Single Page Application)，SPA 的優缺點可以參考[之前寫過的文章](https://lidemy5thwbc.coderbridge.io/2021/07/09/SPA/)。

`react-router-dom` 是在 React 中最受歡迎的處理路由套件，有多受歡迎呢? 在 Github 上有 將近 5 萬個星星；近幾個月都有 800 萬的月下載量。 其中 React 大約有 1600 萬的月下載量，也就是說每兩個用 React 的人便有一個人使用 react-router-dom。
![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/7f092b085d9d6418.png)

你會不會好奇要怎麼自己仿寫一個 React Router 呢? 一起來 Brain Storming 吧!

### 基本使用流程

為了沒有使用過 react-router-dom 的讀者，首先介紹基本語法。
```jsx
import React from "react";
import {
  BrowserRouter as Router,
  Switch,
  Route,
  Link
} from "react-router-dom";

export default function App() {
  return (
    <div className="App">
      <h1>React-router-dom 展示</h1>

      <BrowserRouter>
        <div className="nav">
          <Link to="/">home</Link>
          <Link to="/about">about</Link>
          <Link to="/user/123">user</Link>
        </div>
        <Switch>
          <Route path="/">
            <Home />
          </Route>
          <Route path="/about">
            <About />
          </Route>
          <Route path="/user/:id">
            <User />
          </Route>
        </Switch>
      </BrowserRouter>
    </div>
  );
}
```

-----

從上面這個範例我們挑出四個重要的元件來介紹:

* **BrowserRouter**：BrowserRouter 要包在 SPA 元件的最外層，它提供了 HTML5 History API 的 History 物件讓 UI 與 URL 能夠同步。(接下來會介紹到 HTML5 History API)

* **Switch**：是可以讓第一個符合 URL 的元件會被渲染，所以也可以不加，但通常都會加上 Switch，原因後面會再說明。

* **Route**：Route 元件寫在 Switch 元件底下，負責定義定義元件相對應的 path，當 path 符合目前的 URL 時將會被渲染，如果加上 Switch 可以保證最多只有一個 Route 裏頭的元件會被渲染。

* **Link**：Link 元件負責錨定到不同的路由，其中便是透過操作 BrowserRouter 提供的 History 物件達成。

## 先備工具

在實際開始實作 React Router 之前，還有兩個先備工具要先知道。

### 處理路由的好朋友 - path-to-regexp

path-to-regexp 是一款專門用來處理路由匹配的函式庫，來看看它的用法。
```js
import { pathToRegexp } from './index.js'

const keys = [];
const regexp = pathToRegexp("/user/:id", keys);

console.log(regexp) // /^\/user(?:\/([^\/#\?]+?))[\/#\?]?$/i
console.log(keys) // [{name: "id", prefix: "/", suffix: "", pattern: "[^\/#\?]+?", modifier: ""}]
```

我們可以看到將一個動態的路由以及一個空陣列傳入函式以後，會回傳一個正規表達式可以用來匹配實際的路由，除此之外原本被傳入的空陣列被塞入了動態路由的資訊。

聰明的讀者應該可以很快的想到如果我們有 `/user/michelle` 這樣的實際 url，如果 React 想要解析這個網址得到 `{id: michelle}` 這樣的格式，可以如何運用 path-to-regexp 來達成。如果暫時想不到也可以在後續的實作中練習到~

### 核心中的核心 - HTML5 history API

在開啟瀏覽器時，其實瀏覽器提供的 History 物件讓我們可以操控歷史紀錄。

要使用 HTML history API 我們可以在 window.history 找到它，其中介紹幾種方法:

1. **window.history.back()**：回到上一頁

2. **window.history.forward()**：去到下一頁

3. **window.history.go(N)**：回到上 N 頁

4. **window.history.forward(N)**：去到下 N 頁

5. **window.history.pushState(stateObject, title, url)**：這個方法是 SPA 的精髓，以下分別介紹幾個參數。

* **stateObject**：stateObject 會在 popstate 事件中的 state 屬性出現
* **title**：描述整個頁面
* **url**：這裡提供的 url 可以改變歷史紀錄，新加上一筆，但是**瀏覽器不會實際去這個地址獲取資源**，如此一來我們便可以透過監聽這個事件並透過 js 改變相應的內容來達到 SPA 的效果。
* window.onpopstate(cb)：這個事件會在 pushState 時被觸發。

關於更多細節請直接參考[ MDN 的介紹](https://developer.mozilla.org/zh-TW/docs/Web/API/History_API)。

### 封裝過的 HTML History API - history

不是說先備工具只有兩個嗎??? 其實這個 history 函式庫只是把 HTML5 History API 封裝好，所以基本上算同一個。

history 提供以下幾種產生 history 物件的方法：

* **createBrowserHistory**: 是一個在瀏覽器中使用 HTML5 history API 處理 URL，處理像是這樣的 URL： `example.com/some/path`。切記方法通常必須依賴伺服器端讓 URL 都映射至 index.html，以防第一次進入畫面造成 content not found。
2. **createHashHistory**: 使用 hash tag 處理 URL，比如 `example.com/#/some/path`。 # 後的 URL 不會出現在 HTTP 請求中，所以在請求時都是用 example.com 請求 index.html。
3. **createMemoryHistory**: 適用在沒有 DOM 的環境，例如 React Native。

-----

此外 **location** 是 history 物件中最重要的屬性，提供一個 history.location 的範例 ~

```json
{
  pathname: '/user/lily',
  search: '?key=xxx',
  hash: '#introduction',
  state: { modal: true },
  key: 'eodyw4'
}
```
可以看到裡面除了 url 的路徑以外也提供了 queryString 以及 hash 等資訊。

-----

最後再介紹一個 history 的屬性，`listen` 可以監聽 history.location 的變化。

```js
history.listen((location) => {
  console.log(
    `The current URL is ${location.pathname}${location.search}${location.hash}`
  );
});
```
## 開始手刻 react-router-dom

終於完成先備知識了，那麼以下便開始打造 react-router-dom 吧!

首先我們先由最外層的 BrowserRouter 開始。

### BrowserRouter

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/7cfba963a5adba30.png)

ReactBrowserRouter 是最外層的元件，所以在第 6 行一被渲染時便先創建 history 物件，接著將 history.location 作為 useState 的初始值。

再來注意到第 13 ~ 16 行，只要 history 的路由發生了改變，便會觸發 setState 使得 ReactBrowserRouter 將新的路由向下傳遞給子元件。

可以注意到除了 location 以及 history 以外，還有一個物件被傳遞下去，這個物件的 isExact 屬性表示了這個 url 是否是根路徑。

到這邊我們再回顧一下重要的部分，BrowserRouter 底下的元件會操控 history 物件讓網址更新，不過我們想要讓網頁的內容也隨之更新，所以 BrowserRouter 在監聽到網址變化以後會將新的 location 傳遞到子元件，讓子元件渲染對應的內容。

也就是說會有負責操控 history 的子元件以及負責渲染相對應畫面的子元件對吧! 接下來介紹的 `Switch` 元件將展示如何將網址相對應的畫面渲染出來。

### Switch

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/ba55d30893af6c10.png)

第 12 行到第 22 行的地方 Switch 會迭代每一個底下的 Route 元素，直到 match 的值從初始的 false 變成 true 為止，如此一來透過 Switch 便可以篩選出唯一的 Route。

至於在迭代的過程中要怎麼判斷 Route 上的 path 屬性是否與當前的 pathname 吻合呢? 觀察第 18 ~ 20 行可以看到利用了 matchPath 這個函式判斷，接下來一起來看看 matchPath 是如何操作的。

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/1068fae6b96a3968.png)

沒錯終於到了使用 pathToRegexp 的時候了! 我們以 path 是 `/:id/:name` 以及當前的 pathname 是 `/25/lili` 來說明，第 5 行與第 6 行跟先備工具介紹過的一樣會產生一組拿來匹配 pathname 的正規表達式還有一個陣列裡頭存有各個動態路由的名稱。

第 8 行將 pathname 與正規表達式比對，不吻合則返回 false，如此一來便不會被 Switch 選中，如果吻合的話第 15 到 20 行會返回 `{ id: 25, name: lily }`，這個資訊可以讓 Route 元件底下的子元件使用~

-----

再回到 Switch 元件第 18 到 20 行的地方，如果 Route 沒有定義 path 呢? 那麼 match 會由 BrowserRouter 提供的 match 賦值，也就是說如果把沒有定義 path 的 Route 給放在最前面那麼他就會被 Switch 選中了!

最後 Switch 元件會渲染雀屏中選的 Route 元件並帶入 match 以及 location 做為參數。

### Route

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/a985410905f63d0e.png)

Route 在做的事其實只需要檢查上層有沒有 Switch，檢查的方法是看自己有沒有收到 Switch 提供的 computedMatch 在 props 裡，如果沒有的話需要比照 Switch 檢查 pathname 與 path 是否吻合一樣，最後將 match 給子元件。

### Link

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/d65b7da7bfc8d6db.png)

終於到了最後一個要介紹的元件了~ 也就是負責操控 history 的元件，Link 負責將路由推進 history，接著 BrowserRouter 偵測到了 history.location 的變化，重新渲染以後觸發 Switch 以及 Route 完成一次網址與畫面的連動更新!

### useParams

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/71c0a0a3f57b8652.png)

最後我們再寫一個 hook，使用這個 hook 的元件可以拿到動態路由的參數以及值。

## Recap 回顧

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/5d8be997b06b56e7.png)

透過這張圖來回顧一下 BrowserRouter、Switch、Route 以及 Link 是如何互動的吧!

1. **BrowserRouter 元件**創建了 history 物件並且監聽 history.location 的變化
2. **Link 元件**會觸發 history.push(to) 使得網址列改變且 BrowserRouter 監聽到後重新渲染
3. **Switch 元件**會渲染第一個符合路由的 Route 並將動態路由的參數與值解析出來往下傳遞
4. 如果沒有 Switch 元件每個 **Route 元件**檢查自己的 path 是否與路吻合，如果吻合也一樣解析出動態參數的參數與值向下傳遞
5. Route 底下的子元件渲染出畫面

這次的 react-router-dom 實作篇就到此結束了，下一篇會實作 React 的 Virtual Dom 功能，有興趣的讀者可以先查詢 Virtual Dom 是甚麼。

如果照著步驟仍然無法實做出來的讀者也可以直接參考[完整的程式碼](https://codesandbox.io/s/react-router-dom-uybmz3)。














