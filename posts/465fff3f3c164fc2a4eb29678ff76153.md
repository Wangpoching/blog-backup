---
title: 初探 DNS 系統
---

## 什麼是 DNS？Google 有提供的公開的 DNS，對 Google 的好處以及對一般大眾的好處是什麼？

### 甚麼是 DNS

大家都有用網址連接網站的經驗過吧，以這樣一個網址 `www.ntu.edu.tw` 為例，我們可以猜出一些有關於這個網址的端倪。原來這是位在**台灣**的**教育機構**-**台灣大學**的 www 伺服器裡的網頁內容。

雖然使用網址有語意，但是路由器並看不懂網址，它們只認得 IP 位址。所以必須要有一個資料庫儲存了網址/IP 位址，而這就是 DNS (Domain Name System)，DNS 可以指這樣一個資料庫，也可以指提供這個服務的 Server。在設定網路的時候，會設定 DNS 的 IP 位址，這樣一來瀏覽器便知道要去哪裡找網址對應的 IP。

### DNS 的架構

不知道你有沒有思考過，全世界有這麼多網站，一台 DNS 伺服器怎麼能存取大量資料甚至是順暢的提供服務。

為了解決這個棘手的問題，全世界的網址被區分成許多網域 (Domain)，這些網域有不同的層級，看文字解釋有點模糊，那看看下面這張圖吧!

![img](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/Ikypoty.png)

* Root domain：根網域是 DNS 架構最上層的伺服器，全世界只有 10 幾台，當下層的任何一台 DNS 伺服器找不到對應的 IP 位址時都會找它幫忙。
* Top level domain：頂層網域依照國碼來區分，例如台灣使用 tw、日本使用 jp、如果沒有標註頂層網路則代表美國。
* Second level domain：第二層網域要向各國的網址註冊中心申請，台灣的網域名稱是由台灣網路資訊中心（TWNIC：Taiwan Network Information Center）來管理。每年要繳交費用，舉例來說，台大就購買了第二層網域 ntu.edu。
* Host domain：主機網可以自己設定，依照需要細分成多台主機使用，每一台主機可以設定一個網域名稱，比如說存取網頁的主機叫 www。

### DNS 實際運作

至於 DNS 系統實際上是如何運作的呢? 讓我們以 `www.ntu.edu.tw` 來舉例。

![img](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/CDRtyVL.png)

1. Client 問 預設的 DNS Server：「嗨，請問 `www.ntu.edu.tw` 的地址?」
2. 預設的 DNS Server 找了一下找不到，於是問根網域的 DNS Server：「嗨，請問 `www.ntu.edu.tw` 的地址?」
3. 根網域的 DNS Server：「我不知道 `www.ntu.edu.tw` 的地址? 但我知道 tw 主網域 DNS Server 的地址是 xxx」
4. 預設的 DNS Server 問 主網域 tw 的 DNS Server：「嗨，請問 `www.ntu.edu.tw` 的地址?」
5. 主網域 tw 的 DNS Server：「我不知道 `www.ntu.edu.tw` 的地址? 但我知道 edu.tw 次要網域 DNS Server 的地址是 xxx」
6. 預設的 DNS Server 問 次要網域 edu.tw 的 DNS Server：「嗨，請問 `www.ntu.edu.tw` 的地址?」
7. 次要網域 edu.tw 的 DNS Server：「我不知道 `www.ntu.edu.tw` 的地址? 但我知道 ntu.edu.tw 次要網域 DNS Server 的地址是 xxx」
8. 預設的 DNS Server 問 次要網域 ntu.edu.tw 的 DNS Server，比如說是用 CloudFlare 的 DNS 那就是向 journey.ns.cloudflare.com 問：「嗨，請問 `www.ntu.edu.tw` 的地址?」，那麼因為 Cloud Flare 有一個 `www.ntu.edu.tw` 的檔案，而且檔案裏面有一筆 A 紀錄寫著 140.112.8.116
9. 次要網域 edu.tw 的 DNS Server：「140.112.8.116」
10. 預設的 DNS Server 告訴 Client：「140.112.8.116」

看起來很麻煩，所幸預設的 DNS Server 會把網址/IP 記錄下來，所以除非要造訪冷門網站，否則速度都會很快。

實際上想獲取 IP 位址的時候可以在終端機輸入

```
ping www.ntu.edu.tw
```

會返回 IP 位址

![img](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/NQJLfbi.jpg)

### Google DNS

一般我們申請各種網路服務的時候，網路公司的人員都會幫我們設定好 DNS 伺服器，所以用的也是網路公司（ISP）提供的 DNS 伺服器，但是現在 Google 提供了公用的 DNS 伺服器，以下是 Google DNS Server 的 IP：

* 主DNS伺服器IP(ipv4)： 8.8.8.8
* 次DNS伺服器IP(ipv4)： 8.8.4.4
* 主DNS伺服器IP(ipv6)： 2001:4860:4860::8888
* 次DNS伺服器IP(ipv6)： 2001:4860:4860::8844

如果使用 Google Public DNS 的人多的話，Google 可以統計這些資訊，讓 Google 的搜尋引擎更強化，對使用者以及 Google 都是雙贏。

如果想要更換成 Google public DNS Server可以很簡單的在控制台更改設定，網路上有許多教學文章這裡就不再多佔篇幅了。
