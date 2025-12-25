---
title: 各種在瀏覽器上發送 request 的方法
---

## 什麼是 Ajax？

平常我們在透過網路上發送 request 給 server 來取用 sever 提供的服務時，是由瀏覽器代理，而瀏覽器這時候會自動 render 取得的資料並顯示在網頁上，這件事也許有這麼一點麻煩，因為我們可能會想自己處理取得的資料。打個比方來說，我們想寫一個動態網頁，那取得的資料最好是可以自己先消化過再顯示到網頁上呈現。

說了這麼多，其實要達成這個目的，就要透過 Ajax 的技術，這個技術的重點就在**瀏覽器會把取得的資料丟給 JS 的 runtime，而不會直接呈現在網頁上**。

另外一個還有一個小重點，Ajax 的全名是 Asynchronous JavaScript and XML，Asynchronous 是非同步的意思。同步與非同步的差別在於**大家是否需要互相等待**，在同步的情況底下，程式碼的每一個段落都要排隊，等要求被處理完之後，才輪到下個人，這個情況有點像是大家排隊點餐的狀況，當餐廳出了一份餐，第一個客人拿到餐點才會離開隊伍，然後餐廳才接第二份單。 情況可以想成下面這樣：

```
// 第一份餐　10000000 份鱈魚堡
let count = 10000000;
while(count > 0) {
  count--  
}
console.log('first done')

// 第二份餐一杯冰七喜
let count = 1;
while(count > 0) {
  count--  
}
console.log('second done')
```

第二份餐點明明就比較快做完阿，但是還要等第一道餐點做完才能輪到第二道餐點，好麻煩！

我可能會比較想老闆在做 10000000 份鱈魚堡的時候，請另一個店員用飲料機先幫你把冰七喜裝好給你，而令人開心的是，Ajax 可以達成這樣的功能，這就是所謂的非同步。

而為甚麼 Ajax 要支援非同步呢？因為 Ajax 是跟 server 要資料，屬於比較耗時的工作，如果 Ajax 是同步的話，那當執行到 Ajax 的時候，網頁上牽涉到 JS 的功能都會凍結，因為大家都要排隊等 server 傳回資料。


## 用 Ajax 與我們用表單送出資料的差別在哪？

假設我們設計了一個表單，並且寫了 123 並送出。

```HTML
<!DOCTYPE html>

<html>
<head>
  <meta charset="utf-8">
  <title>Twitch-TopGames</title>
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
</head>

<body>
  <form method="GET" action="https://google.com">
    <input type="text" name="user">
    <input type="submit">
  </form>
</body>
</html>
```

瀏覽器會幫我們把 name=123 用 querystring 的方式送 request 給 google.com，接著網頁便自動跳轉成 google.com 回傳的資料。

但如果我們使用 Ajax，如同之前提到的，**瀏覽器會把取得的資料丟給 JS 的 runtime，而不會直接呈現在網頁上**，也就是說使用 Ajax 不會發生頁面跳轉。

## 要如何存取跨網域的 API？

當我們用 AJAX 傳送資料的時候，發現了新的問題。

```HTML
<!DOCTYPE html>

<html>
<head>
  <meta charset="utf-8">
  <title>test AJAX</title>
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
</head>
<body>
</body>
<script>
  const request = new XMLHttpRequest()
  request.onerr = function () {
    console.log('error')
  }
  request.onload = function() {
    console.log(response.text)
  }
  request.open("GET", 'https://www.google.com', true)
  request.send()
</script>
</html>
```

打開　devtool 顯示這樣的錯誤訊息：

```
Access to XMLHttpRequest at 'https://www.google.com/' from origin 'null' has been blocked by CORS policy: No 'Access-Control-Allow-Origin' header is present on the requested resource.
```

這是因為瀏覽器因為安全性的考量，要遵守同源政策（Same-origin policy）的規範。

同源代表 Domain 相同，端口號也要相同，所以 http 跟 https 不同源，而不同的網域底下也不同源。

當 client 與 server 端不同源的時候，瀏覽器還是會發 request，但是會把 response 給擋下來，不讓 JS 拿到。這限制很大呢，要怎麼解決呢？

這個時候要介紹 CORDS（Cross-Origin Resource Sharing，跨來源資源共享），這個規範替同源協定制定了通融的情況，如果想開啟跨來源 HTTP 請求的話，Server 必須在 response 的 header 裡面加上 Access-Control-Allow-Origin 的選項，很熟悉吧，因為剛剛錯誤提示裡就有提到了。

接下來實際來看一下開放比較寬鬆的 server 是如何制定 Access-Control-Allow-Origin 的。這邊以 twitch 當範例，詳細使用 api 的說明請參考[這裡](https://dev.twitch.tv/docs/v5)，請自己申請一個 client ID。

```HTML
<!DOCTYPE html>

<html>
<head>
  <meta charset="utf-8">
  <title>test AJAX</title>
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
</head>
<body>
</body>
<script>
  const CLIEND_ID = 'xxx'
  const ACCEPT = 'application/vnd.twitchtv.v5+json'
  const request = new XMLHttpRequest()
  request.onerr = function () {
    console.log('error')
  }
  request.onload = function() {
    console.log(request.responseText)
  }
  request.open("GET", 'https://api.twitch.tv/kraken/games/top?limit=5', true)
  request.setRequestHeader('Client-ID', CLIEND_ID)
  request.setRequestHeader('Accept', ACCEPT)
  request.send()
</script>
</html>
```

而 response 的 header 是這樣子的：

```
access-control-allow-origin: *
content-encoding: gzip
content-length: 625
content-type: application/json; charset=utf-8
date: Sat, 05 Jun 2021 07:49:56 GMT
strict-transport-security: max-age=300
timing-allow-origin: https://www.twitch.tv
vary: Accept-Encoding
x-cache: MISS, HIT
x-cache-hits: 0, 2
x-served-by: cache-sea4420-SEA, cache-nrt18340-NRT
x-timer: S1622879396.289021,VS0,VS0,VE0
```

注意到了嗎？ access-control-allow-origin: *，星號代表萬用符號，所以 twitch api 是支援跨網域傳輸資料的，另外，除了 access-control-allow-origin 這個 header 以外，server 端也可以透過 Access-Control-Allow-Headers 還有 Access-Control-Allow-Methods 來限制 request 的 header 以及方法。

## JSONP 是什麼？

其實還有其他在瀏覽器上發送 request 的方法，不僅**不會跳轉畫面**也**不用遵守同源限制**。

其實在寫 HTML 的時候，我們常用的 script 標籤常常透過 src 屬性用 GET 的方式跨網域拿到資料。

這種方式有個衍伸的方法可以拿到資料，這個方式就叫做 **JSONP（JSON with Padding）**。

server 端可以透過這個方法來傳資料，只要把內容包在一個函式裡面，而 client 端則定義函式的動作即可，像是 twitch 就有提供這樣的方式，使用者要再額外提供函式的名稱來讓 twitch server 把資料放在函式的參數裡。

比如說我們在 HTML 裡寫：

```HTML
<script>
  function getData(res) {
    console.log(res);
  }
</script>
<script src="https://some.com/api?funcname=getData"></script>
```

這邊是假設有一個支援 JSONP 模式的 server，使用者在 querystring 掛上函式的名稱，把 call api 放在後面是因為要先定義好函式否則會報錯，
以這個例子來說，假設資料是 123， server 就會回傳：

```
getData('123')
```

最後我們就可以在 devtool 的 console 上看到 '123' 被印出來，但是要注意 JSON 只支援最基本的 get 方法。 

## 為什麼我們在用 nodeJS 時沒碰到跨網域的問題，現在卻碰到了？

同源政策是瀏覽器提供的限制，如果我們沒有透過瀏覽器，而是像之前一樣直接使用 nodeJS 使用作業系統提供的 API 發送的話，server 回傳的資料就不會被瀏覽器阻擋，值得注意的是在瀏覽器上透過 Ajax 發送 request 時，**request 一樣會送出，一樣會收到 response**，只不過如果非同源的話，**瀏覽器便不會把資料轉交給 JS 去處理**。
