---
title: 不用框架實作 React 第一次渲染 SSR + Routing
---

# 實作 React 版本的 SSR + CSR

## 架構

在網路上看到許多定義 SSR 指的是瀏覽器第一次請求內容使用 SSR，但後續還是使用 CSR 的方式。

為了不要混淆讓人以為所有畫面的改變都是使用 SSR，所以我把這樣的方法稱作 1st SSR + CSR。

在實作 React 版本的 SSR + CSR 以前，先大致瀏覽一下架構這次實作的架構。

![img](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/fgzpfHW.png)

這個架構有幾個特色:

* 渲染伺服器與瀏覽器端都可以請求 API。
* 渲染伺服器會在使用者請求 HTML 時，會請求 API 的資料，並將內容都事先放到 HTML 中。
* 在第一次請求 HTML 後，之後的元件 routing、請求 API 都是在瀏覽器端執行。

## 事前準備

第一步要安裝需要的套件，可以照著底下節錄的 package.json 安裝。

```json
"dependencies": {
  "express": "^4.17.2",
  "prop-types": "^15.7.2",
  "react": "^17.0.2",
  "react-dom": "^17.0.2",
  "react-router-dom": "^6.2.1",
  "webpack-node-externals": "^1.7.2"
},
"devDependencies": {
  "@babel/core": "^7.10.4",
  "@babel/preset-env": "^7.10.4",
  "@babel/preset-react": "^7.10.4",
  "babel-loader": "^8.1.0",
  "nodemon": "^2.0.4",
  "npm-run-all": "^4.1.5",
  "webpack": "^4.43.0",
  "webpack-cli": "^3.3.12",
  "webpack-node-externals": "^1.7.2"
}
```

### express

express 作為撰寫渲染伺服器的框架，能夠在使用者請求 HTML 時，決定要渲染哪個元件，或者是呼叫 API 請求資料，並將資料渲染至 HTML 中，最後以**字串**回傳 HTML。

### webpack + babel

因為不用 create-react-app 打包 react 的關係，所以需要自己動手打包。

除了需要讓 babel 轉換 JSX 的語法之外，也記得要讓 ES6 轉 ES5 語法，因為 server 是跑在 node 環境，對 ES6 的支援度不高。

### nodemon

nodemon 可以取代 node 執行 js 程式，厲害的是類似於 dev server，nodemon 會隨時監聽執行程式有沒有被修改，並且重新執行。

### npm-script(package.json)

先看一下在 package.json 中定義的幾個快捷指令:

```json
"scripts": {
  "dev": "npm-run-all --parallel dev:build:* dev:server ",
  "dev:server": "nodemon --inspect build/bundle.js",
  "dev:build:server": "webpack --mode development --config webpack.server.js --watch",
  "dev:build:client": "webpack --mode development --config webpack.client.js --watch"
}
```

當輸入指令 `npm run [npm-script]`時，會自動執行定義好的 command。

下面是各個指令的功能:

* dev:build:server：使用 webpack 打包 server 端程式碼 (express)，並監聽程式碼的改變，自動編譯程式碼。
* dev:build:client：使用 webpack 打包 client 端程式碼 (react)，並監聽程式碼的改變，自動編譯程式碼。
* dev:server : 使用 nodemon 監聽 bundle.js 是否有改變，自動執行 bundle.js
* dev: 偷懶一波，直接把前三個指令都下了

### 如何將 React Component 轉為文字

進入實作的第一個困難是，有沒有甚麼方法可以很方便的將 React Component 轉成 html tags 呢? 

記得在第一次渲染的時候，我們希望渲染伺服器可以給瀏覽器 html，如果我們希望搭配 react 達成這件事情的話，react 已經提供了這樣的函式。

我們來看看 `renderToString` 這個函式在[官網的介紹](https://zh-hant.reactjs.org/docs/react-dom-server.html#rendertostring)

> React 將會回傳一個 HTML string，你可以使用這個方法在伺服器端產生 HTML，並在初次請求時傳遞 markup，以加快頁面載入速度，並讓搜尋引擎爬取你的頁面以達到 SEO 最佳化的效果。

### 資料夾結構

```
│  .babelrc
│  package.json
│  webpack.client.js
│  webpack.server.js
└─src
    │ server.js
    │ client.js
    │ App.js
    └─pages
    │   │ HomePage.js
    │   │ OtherPage.js
    └─helpers
    │   │ renderer.js
    └─components
        │ Header.js
```

## 開始寫 React Components

### Pages

這個實作會有兩個分頁，叫做 HomePage 與 OtherPage。

```jsx
// HomePage
import React from 'react'

const HomePage = () => (
  <div>
    <h1>HomePage</h1>
    <h2>Hello! I am HomePage!</h2>
  </div>
)

export default HomePage
```

OtherPage 比較特別一點，我們加上一個按鈕以及 EventListener，每按一下都會在 console 收到通知。

```jsx
import React from 'react'

const OtherPage = () => (
  <div>
    <h1>OtherPage</h1>
    <button onClick={() => console.log("click me")}>click me</button>
  </div>
)

export default OtherPage
```

### Header (切換頁面)

為了方便切換頁面，接著要切一個 Header。

```jsx
import React from 'react'
import { Link } from 'react-router-dom'

const Header = () => (
  <ul>
    <li>
      <Link to="/">Home</Link>
    </li>
    <li>
      <Link to="other">Other page</Link>
    </li>
  </ul>
)

export default Header
```

## 建立渲染伺服器 (Express)

這個 express 渲染伺服器，提供 `/` 與 `/other` 的 GET API，在使用者進入 localhost:3001 時，會選擇元件 `<HomePage />` 或是 `<OtherPage />` 轉換成 HTML 字串，然後回傳。

```js
import express from 'express'
import renderer from './helpers/renderer'

const app = express()

const port = process.env.PORT || 3001

app.get('/', (req, res) => {
  const content = renderer(req)
  res.send(content)
})

app.get('/other', (req, res) => {
  const content = renderer(req)
  res.send(content)
})

app.listen(port, () => {
  console.log(`Listening on port: ${port}`)
})
```

## 建立 helper function

不是說要用 `renderToString` 把元件轉成 html 嗎? 我們把這個邏輯抽成一個叫做 renderer 的 function。

```jsx
import React from 'react'
import { renderToString } from 'react-dom/server'
import { StaticRouter } from 'react-router-dom/server'
import { Route, Routes } from 'react-router-dom'
import HomePage from '../pages/HomePage'
import OtherPage from '../pages/OtherPage'
import Header from '../components/Header'

export default (req) => {
  const content = renderToString(
    <StaticRouter location={req.path}>
      <Header />
      <Routes>
        <Route exact path='/' element={<HomePage />} />
        <Route exact path='/other' element={<OtherPage />} />
      </Routes>
    </StaticRouter>
  );
  return `
    <html>
      <body>
        <div id="root">${content}</div>
      </body>
    </html>
  `
}
```
這邊有趣的是使用了 Static Router 當作路由，Static Router 會實際依照網址來渲染內容，所以在第一次使用 SSR 渲染時，就可以根據網址來將對應的元件傳換成 Html。

如果使用 Browser Router 是行不通的，因為 Browser Router 要使用到 document 上的函式，但是在第一次使用 SSR 的時候內容是放在 HTML 裡的，那時候尚未有 document 可以使用。

## 設定 babel

接著準備要 compile，所以要先把 babel 的設定寫在 .babelrc 裡頭。

```
{
  "presets": [
      "@babel/preset-env",
      "@babel/preset-react"
  ]
}
```

這兩個 preset 是為了因應我們在 node.js 的環境中會用到 React 的 JSX 語法，而且可能會用到比較新的 JavaScript 語法。

## webpack 設定檔

最後只要寫好 webpack 設定檔就可以 compile 了。

```js
// webpack.server.js
const path = require('path')
const webpackNodeExternals = require('webpack-node-externals')

module.exports = {
  target: 'node', //使用 node.js 的環境編譯程式碼。
  entry: './src/server.js', // 入口點
  externals: [webpackNodeExternals()], // 因為在 node 中可以另外引入相依套件，所以不用把 node_modules 都打包
  output: {
    filename: 'bundle.js', // 打包後的檔案名稱
    path: path.resolve(__dirname, './build'), // 打包後的檔案路徑
  },
  module: {
    rules: [
      {
        test: /.js$/,
        use: {
          loader: 'babel-loader',
          options: {
            presets: ['@babel/preset-react', '@babel/preset-env'], // 可以寫在 .babelrc 也可以寫在這裡
          },
        },
      },
    ],
  },
  devServer: {
    port: 8080,
  },
};
```

## 打包並執行 bundle

在 cmd 輸入以下指令進行打包與開啟 express server

```cmd
npm run dev:build:server
```
```cmd
npm run dev:server
```

接著在瀏覽器輸入 localhost:3001 測試。

![img](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/9eIU60T.gif)

有兩個問題需要改善：
1. 點了按鈕 console 怎麼沒有提醒?
2. 使用 Static Router 每次點擊超連結都會實際換頁，想要有 SPA 怎麼辦?

## 把第一次渲染之後的工作交給 Client Side

記得前面提到我們希望把第一次渲染之後不管是監聽或是換頁等等的工作都交給瀏覽器嗎?

所以只要在第一次渲染之後的換頁都採用 Browser Router 就沒有換頁的問題了。

至於 EventListener 的問題也是因為純文字的 Html 並沒有辦法加上 EventListener，所以也必須仰賴 Client 端在第一次渲染以後另外加上。

我們再看一次[之前的第一次渲染使用 CSR vs SSR 的比較圖](https://lidemy5thwbc.coderbridge.io/2022/01/29/CSR-SSR/):

![img](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/q914jq2.png)

接著我們試著把紅色框的部分完成。

## Client.js

我們除了前面用 webpack 打包 express 的程式碼，現在還要多一個在使用者看到網頁內容後，用於綁定事件以及支援 BrowserRouter 的 JavaScript 檔案。

```jsx
//client.js
import React from 'react'
import ReactDOM from 'react-dom'
import App from './App'

ReactDOM.hydrate(
  <App />,
  document.getElementById('root')
)
```

接著把 Browser Router 寫在 App.js 裡面

```jsx
//App.js
import React from 'react'
import { BrowserRouter, Route, Routes  } from 'react-router-dom'
import HomePage from './pages/HomePage'
import OtherPage from './pages/OtherPage'
import Header from './components/Header'

const App = () => (
  <BrowserRouter>
    <Header />
      <Routes>
        <Route exact path='/' element={<HomePage />} />
        <Route exact path='/other' element={<OtherPage />} />
      </Routes>
  </BrowserRouter>
);

export default App
```

到這裡眼尖的人應該會注意到在 client.js 裡我們使用 ReactDOM.hydrate 而不是 ReactDOM.render。

官方網站這樣子介紹 ReactDOM.hydrate :

> 如果你在一個已經有伺服器端 render markup 的 node 上呼叫 ReactDOM.hydrate，React 將會保留這個 node 並只附上事件處理，這使你能有一個高效能的初次載入體驗。

所以說使用 React.hydrate 的話可以保留 SSR 與 CSR 相同的部分，節省了一些效能。

## webpack.client.js

接著當然要把 client.js 也 bundle 起來，就像 create-react-app 做的一樣。

```js
//webpack.client.js
const path = require('path');

module.exports = {
  entry: './src/client.js',
  output: {
    filename: 'bundle.js',
    path: path.resolve(__dirname, './dist'),
  },
  module: {
    rules: [
      {
        test: /.js$/,
        use: {
          loader: 'babel-loader',
          options: {
            presets: ['@babel/preset-react', '@babel/preset-env'],
          },
        },
      },
    ],
  },
  devServer: {
    port: 8080,
  },
};
```

因為這一包是要在瀏覽器上執行的，所以記得要連 node_modules 都一起包起來。

## renderer.js

記得再回到 renderer.js 把打包好的 client.js 給引入到 html 裡的 script 標籤。

```jsx
//renderer.js
import React from 'react'
import { renderToString } from 'react-dom/server'
import { StaticRouter } from 'react-router-dom/server'
import { Route, Routes } from 'react-router-dom'
import HomePage from '../pages/HomePage'
import OtherPage from '../pages/OtherPage'
import Header from '../components/Header'

export default (req) => {
  const content = renderToString(
    <StaticRouter location={req.path}>
      <Header />
      <Routes>
        <Route exact path='/' element={<HomePage />} />
        <Route exact path='/other' element={<OtherPage />} />
      </Routes>
    </StaticRouter>
  );
  return `
    <html>
      <body>
        <div id="root">${content}</div>
        <script src="./bundle.js"></script> // 記得加上 bundle.js
      </body>
    </html>
  `;
};
```

## express

最後可能忽略的小細節是幫 express 指定靜態檔案的路徑，指定路徑為打包好的 client.js 放的 dist 資料夾。

```js
// server.js
import express from 'express'
import renderer from './helpers/renderer'

const app = express()

const port = process.env.PORT || 3001

app.use(express.static('dist')) // 指定靜態資源路徑

app.get('/', (req, res) => {
  const content = renderer(req)
  res.send(content)
})

app.get('/other', (req, res) => {
  const content = renderer(req)
  res.send(content)
})

app.listen(port, () => {
  console.log(`Listening on port: ${port}`)
})
```

## 最終打包

在 cmd 執行:

```cmd
npm run dev:build:server
```
```cmd
npm run dev:build:client
```
```cmd
npm run dev:server
```

或者開大決:

```cmd
npm run dev
```

開啟 localhost:3001 來測試看看吧! 為了測試 Static Router，這次從 localhost:3001/other 進入。

![img](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/B2964Qe.gif)

這次換頁不用重新向伺服器請求而且點擊按鈕 EventListener 也成功監聽了，完美!

## 補充

如果不想一步一步來的話可以直接參考[這裡](https://github.com/Wangpoching/react-ssr-router-tutorial)。

想知道全部使用 CSR 以及第一次渲染使用 SSR 的優劣可以看[前一篇](https://lidemy5thwbc.coderbridge.io/2022/01/29/CSR-SSR/)。