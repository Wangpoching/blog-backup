---
title: Client Side Rendering(CSR) 的缺點與優化
---

## CSR vs SSR

CSR (Client side rendering) 與 SSR (Server Side rendering) 有甚麼不同呢? 

在深入這個問題之前，可以先看下面這張圖:

![img](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/p5wLxq4.png)

### CSR

首先先看 CSR，許多的 SPA 的網站都利用 CSR 來實現，為了實現瀏覽器不用請求新的頁面就達到換頁的效果，可以讓 Javascript 負責畫面元件的渲染，造成**換頁的效果**。

圖中以 React 為例，首先瀏覽器請求 Html，不過大部分的情況下，瀏覽器只會收到一個很空的 Html，像下面的範例一樣。

```html
<!doctype html><html lang="en"><head><meta charset="utf-8"/><link rel="icon" href="/react-blog-redux-/favicon.ico"/><link href="https://fonts.googleapis.com/css2?family=Noto+Sans+TC:wght@400;500;700;900&amp;display=swap" rel="stylesheet"/><meta name="viewport" content="width=device-width,initial-scale=1"/><meta name="theme-color" content="#000000"/><meta name="description" content="Web site created using create-react-app"/><link rel="apple-touch-icon" href="/react-blog-redux-/logo192.png"/><link rel="manifest" href="/react-blog-redux-/manifest.json"/><title>React Redux App</title><script id="react-dotenv" src="https://wangpoching.github.io/react-blog-redux-/env.js"></script><script defer="defer" src="/react-blog-redux-/static/js/main.9d047363.js"></script><link href="/react-blog-redux-/static/css/main.412967fc.css" rel="stylesheet"></head><body><noscript>You need to enable JavaScript to run this app.</noscript><div id="root"></div></body></html>
```

有趣的是除了 id 名叫 root 的 div 元素以外，body 是空的。不過在 header 裡頭會請求 compile 好的 javascript 檔案，負責諸如監聽、渲染以及發 API 等大大小小的工作。

最後使用者得以看到畫面。

### SSR

再來看到 SSR 的部分，SSR 代表當瀏覽器請求 Html 時，網頁的內容已經被寫在 Html 裡了，因此瀏覽器在解析完 css 與 html 後會自動渲染畫面，而不是由 javascript 所操縱渲染畫面。

在 SSR 的情況下瀏覽器一開始收到的 Html 是類似下面的範例的，可以看到畫面需要呈現的內容幾乎都寫在 body 裡頭了。

```html
<!DOCTYPE html>

<html>
<head>
  <meta charset="utf-8">
  <title>lazy-form</title>
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <link rel="stylesheet" href="./normalize.css">
  <link rel="stylesheet" href="./modal.css">
  <script src="./index.js"></script>
</head>

<body>
  <div class="all__wrapper">
    <div class="form__wrapper">
      <div class="wrapper">
        <section>
          <h1>Todo List</h1>
        </section>
      </div>
      <div class="wrapper">
        <section class= 'query-block'>
          <input class="input__text" type="text" placeholder="Add something to do here <(￣︶￣)>?">
          <div class="input__underline"></div>
        </section>
      </div>
      <div class="wrapper">
        <section class= 'main-block'>
          <ul>
            <li>
                <label>
                    <input class="todo" type="checkbox" />
                    <div>開會</div>
                </label>
                <div class="btn__delete"><div>
            </li>
            <li>
                <label>
                    <input class="todo" type="checkbox" />
                    <div>遛狗</div>
                </label>
                <div class="btn__delete"><div>
            </li>
            <li>
                <label>
                    <input class="todo" type="checkbox" />
                    <div>掃客廳</div>
                </label>
                <div class="btn__delete"><div>
            </li>
          </ul>
        </section>
      </div>      
    </div>
  </div>
</body>
</html>
```

## CSR 的缺點

雖然使用 CSR 的方式寫 SPA 很方便，而且像是 React, Vue 等等的框架可以省去把資料與畫面的邏輯混著寫的麻煩，那幹嘛要用 SSR?

因為 CSR 是由前端的 JavaScript 動態產生內容，所以當檢視原始碼時，只會看到空蕩蕩的一片，只看得到一個 JavaScript 檔案。

對於 SEO 來說，簡直糟透了，不過 Google 的爬蟲其實支援執行 JavaScript，所以也許他有辦法知道實際的內容。

不過問題是除了 Google，還有其他很多搜尋引擎並沒有執行 JavaScript 的機制。

## 解決辦法

有沒有甚麼辦法可以融合 SSR 還有 CSR 的優點呢? 如果可以**在第一次請求 HTML 時使用 SSR，之後元件的  routing、請求 API 都是在瀏覽器端執行，**這樣一來有許多優點。

1. 利於進行 SEO
2. 減少使用者從請求網頁到看見網頁內容時間
3. 仍然有 SPA 的優點

至於要怎麼實作，會在[下一篇](https://lidemy5thwbc.coderbridge.io/2022/01/30/react-ssr-routing-tutorial/)討論。