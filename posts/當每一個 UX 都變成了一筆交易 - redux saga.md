---
title: 當每一個 UX 都變成了一筆交易 - redux saga
---

## 甚麼是 Saga

一個 Saga 是甚麼，這邊就直接解答了，一個 Saga 我們可以將它看作一個 **LLT (Long lived transaction)**。

transaction 在資料庫裏面代表一筆交易，一個交易如果失敗了，則資料庫的狀態必須回到交易前的時間點。為了要保持資料的完整性，必須確保一個交易會碰到的資料表或是資料列無法被其他交易操作。

當一筆交易如果非常久，那麼很容易造成**資料庫鎖死大塞車**的情況。另一個問題是長時間的交易容易**累積高失敗率**。

等等，剛剛前面是不是有說 Saga 是一個長時間的交易... 值得慶幸的是 Saga 是一個特別的 LLT，接下來我們來看看它運用了甚麼概念解決 LLT 的問題!

### 從芒果椰奶冰淇淋開始

我們拿最近全家在賣的芒果椰奶冰淇淋為例子。
![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/fe765ca292b9a4f6.jpg)

假設每一家店要在每天的最後計算賣出去的芒果椰奶冰淇淋的總枝數，這個持續一整天的統計其實就是一個 LLT，而每一次購買是一個小小的 transaction，這就是 Saga 的第一個特別之處，一個大的 Saga 可以由許多小 Saga 組合而成。

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/353552830b4c979d.png)

當客人買了一根冰淇淋，小的 transaction 就會記錄一次加 1，最後到關店前統計總共賣掉了幾支，一切看起來都很棒對吧!

### 退貨機制

全家的總公司為了維護品質，決定讓店員統一擠 3 圈冰淇淋，像下面這樣。

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/990f4dc81b841b49.jpg)

如果不是剛好 3 圈，客人可以退貨!

讓我們回想 Transaction 的特性，如果途中有操作失敗的話，就要回復到 Transaction 前的狀態。

這樣不就等於有一個客人退貨，就要把賣出的總數退回到當初退貨的客人買冰淇淋的時間點嗎?

### 只要補償失敗的交易即可

聰明的你肯定知道如果有一個客人來退貨，只要將賣出的總數 -1 就好了嘛! 這樣整個大的 Transaction 即使其中有小的 Transaction 失敗也可以繼續執行，並且仍然保持資料的一致性。

將賣出的總數 -1 這件事就叫做一個 **compensating transaction**，這就是 Saga 特別的地方，我們只是把賣的枝數從 database 裡面減掉而不是讓 database 回到退貨的客人買冰淇淋發生前的時間點。

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/bc66dfe45e28c739.gif)

## Redux-Saga vs. Redux-Thunk

講完了理論讓我們來看看實作，雖然交易 (Transaction) 的概念常常被應用在資料庫，但是前端的 UX 也可以應用交易的概念呢!

想像一個登入流程：
1. 送出登入 request
2. 畫面進入 loading 畫面
3. 登入結果
  * 如果登入成功
    * 取得 token 並快取起來 
    * 拿到 username 並顯示
  * 如果登入失敗
    * 顯示登入失敗

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/e8fce3edee310714.gif)

### 使用 Thunk 來寫

既然登入要 Call API，很多人就會想到要用 Redux-Thunk 來寫，實際上是完全沒問題的! 下面的程式碼是用 thunk 寫的登入流程：

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/570fe84716980291.png)

首先在 Reducer 裡面定義了幾種改變狀態的 action，分別是初始狀態 `init`、登入中狀態 `loading`、登入成功狀態 `logined` 以及登入失敗的狀態 `error`。

問題是我們需要 Call 登入的 API 並且根據結果來發出成功或者失敗的 action，顯然單純的 action 並沒有辦法寫出這樣的邏輯。

**Thunk comes to rescue!**

如果在 Redux 啟用 thunk 的 middleware，那麼在每次 dispatch 之前，thunk 會先把關，如果 dispatch 一個函式，**thunk 會先跑過這個函式**，而這個函式會接收 dispatch 為參數，所以可以完成 Call API 並根據結果來決定要 dispatch 登入失敗或者登入成功。

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/f4b5a8c9adbf10ce.png)

### Redux Thunk 的不足

Thunk 的確實現了我們希望的登入功能，但是如果我們真的把登入流程看成一筆交易，我們需要處理**使用者反悔了，不想登入**的情況。

Thunk 很難寫出這樣的邏輯，原因在於 promise 是不可逆的，當 promise 一執行我們只能等待黑箱作業的結果。

此外，Call API 也難以做測試，如果要測試還必須要模擬一遍。

別擔心，Saga 既然作為一個 LLT，它可以支援交易的失敗(取消登入)。

## 用 Saga 實作一個登入流程

### 事前準備

#### package.json

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/385bfb35ea2f4772.png)

* 測試
    * npm run compile
    * npm run test
* 運行
    * npm run build
    * node server.js

在 package.json 裡面可以看到測試以及打包用的指令。測試前需要將原始碼用 babel 轉成 es5 才能用 mocha 來測試。

要運行前則需要將原始碼用 webpack 打包，然後啟動 server。

接著來看看 babel 以及 webpack 的設定檔。

#### .babelrc

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/f0ff5dc4b15e9729.png)

需要透過 babel 轉譯 JSX 以及 ES6 的語法。

#### webpack.config.cjs

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/8317330c3942e73e.png)

webpack 透過 babel 轉譯以後再打包 css 成為一個 js 檔。

### 前端元件

我們從使用者的角度來思考，要做出什麼樣的登入介面，下面是我們希望的成品。

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/9ab85c0e22e2eaad.gif)

跟之前不同的是使用者可以在 loading 等待時取消登入流!

#### Container

Container 負責 UI 最外層的樣式。

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/4e6c08c712b700f9.png)

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/1984f3d8dbacd667.png)

#### Login

Login 負責使用者輸入帳密的介面以及登入按鈕。

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/b88154476b5cff8b.png)

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/5efaf76268afa639.png)

####  Loading

Loading 負責顯示旋轉等待登入的 UI (包含取消)。

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/34cbff0b3eb4747d.png)

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/ee12459cd7b17b09.png)

#### User

User 元件在登入成功以後顯示使用者名稱以及核發的 token。

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/c11c21c62eb5ee86.png)

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/39e23908e49b13d4.png)

#### 掛載到 Root

最後把上面被 React 操作的元件掛載好，UI 便告一段落了。

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/0d95f9db64c96ba0.png)

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/ccf6583960d3ce8c.png)

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/405537d7338ad224.png)

### Server

為了發送 API 以及讓其他人可以使用登入介面，就要連 Server 都建起來了XD

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/832cda35d819a35e.png)

* 第 15 行，定義靜態資源路由 (webpak 打包好的 js 檔)
* 第 17 ~ 25 行，定義登入介面路由
* 第 27 ~ 47 行，定義登入 API
* 第 55 行，Server 預設監聽 8889 連接埠

### Fetch

接著把前端呼叫 API 的方法給定義好。

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/0b4a008b394ec36f.png)

* **checkStatus**: 檢查狀態碼是否是 200 ~ 299，否則噴錯
* **parseJSON**: 將 response 轉成 JS literal 物件
* **fetchAPI**: fetch 模板
* **loginAPI**: 參數代入帳密便可以使用 fetchAPI 將帳密放在 body 送出

### Redux Store

終於要開始寫 Saga 的邏輯了，首先我們要將 Redux Store 給掛上 Redux Saga 的 middleware，然後選擇讓哪些 Saga 跑起來。

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/c9524c30b00f8606.png)

* 第 13 行，把 Redux Saga middleware 掛到 store 上
* 第 17 行，將 Root Saga 跑起來

### actions

action 是一個物件，而 reducer 可以根據現在的 state 以及 action 的類型來產生新的 state。

> reducer(state, action) => newState

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/e9fb3e466f508093.png)

### reducers

雖然讀者應該很想看看 Root Saga 的廬山真面目，不過還是得先完成 boilerplate 很繁複的 redux 設定。

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/064fa2718cb797cf.png)

雖然這次的 reducer 只有 login 一個，但是在一般的專案裡會拆分成許多不同的 reducer 再合併，這裡便還是將 login 給包進大的 reducer 裡。

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/2c5af7a2754f6d09.png)

### saga

我們來看看 Saga 要怎麼寫，一個 Saga 可以由許多小 Saga 組成，Saga 的長相是一個 generator Function。

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/67c8aedbaa63640f.png)

* 第 21 行，監聽每次發出登入 API 的 action，並啟動另外一個 loginFlow Saga
* 第 45 行，非同步運行另一個 authorize Saga 開始登入流程
* 第 47 行，監聽登入失敗的 action，並取消 authorize Saga
* 第 27 行，呼叫登入 API
* 第 32 行，如果沒有丟錯便送出登入成功的 action
* 第 37 行，如果登入失敗便送出登入失敗的 action

在一般的專案裡會有許多 Saga 併行，雖然這邊只有登入的 Saga，仍然讓讀者看看如何使 Saga 併行。

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/f8c1cff3460c2e7b.png)

到此為止我們可以思考一下 watchRequestLogin 其實就是一個最上層的 saga，底下有 authorize 以及 loginFlow 兩個 saga，當 authorize saga 失敗(使用者取消登入時)，並不會停止整個 watchRequestLogin saga，事實上登入的操作仍持續被監聽著，只是取消的那次登入，無論送出登入要求的結果是成功或失敗都不會再被處理。

### 測試

Saga 除了解決 LLT 高失敗率的問題以外還有方便測試的好處，怎麼說呢? 事實上，`takeEvery`、`call`、`put`、`fork`、`take`、`cacel` 等等 Helper Function 的回傳值都是 JS Literal Object 喔! 也就是說我們在測試時只要遍歷 Saga 並確保物件的相等即可!

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/4c16e863511c46b4.png)

最後也要記得測試 reducer 是否照我們所想的邏輯運作。

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/6f0bff2cf90c6eee.png)

## 結語

這次示範了如何將 saga pattern 運用在前端 UX，我們有很大的自由度選擇
要不要加上 compensating transaction。

除此之外，非同步 action 變得更好測試了，因為我們只需要比對物件而不需要真的模擬發送 request。

想要看這次的成品可以上[這裡](https://codesandbox.io/s/redux-saga-demo-5fyxx6)，如果想要連測試還有 server 都在本地跑請到[這裡](https://github.com/Wangpoching/redux-saga-demo)複製 repository。

最近在建置兩廳院的多視角直播系統，因此有碰到即時通訊的部分，在 web 的即時通訊技術裡面 webRTC 可以實現 client to client 的資訊交換。下一篇系列文應該會在年底才會寫，因為想要實做一個即時通訊的網頁，之後再把當中的技術跟大家分享囉! 在此立下年底完成的 Flag^^