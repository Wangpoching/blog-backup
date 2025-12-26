---
title: Session 機制是甚麼碗糕
---

## HTTP 是無狀態的

在網路上發送 request 的時候，我的意思是，每一個 request 都是不相干的。從下面這張圖也許你會比較了解我的意思：

![Imgur](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/y6v2cW1.png)

當早餐店老闆娘總是沒辦法記住你常點的餐點，感覺十分沒人情味對吧! 有甚麼解決辦法呢? 如果你常買帕尼尼，那就請老闆在你第一次點餐的時候，給你一張紙條寫著：「常買品項: 帕尼尼」。

到這裡你可能會有點疑惑，寫在紙張上跟直接講有比較方便嗎? 事實上還真的方便了一點點，因為你每次只要拿出紙條給老闆看就好了，實際上點餐只有在第一次的時候需要口頭說。

用紙條來記憶的方式會像下面這樣：

![Imgur](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/u9wKGY3.png)

其實在網路的世界裡，可以讓 HTTP 產生狀態的機制就叫做 **Session**。

所以 Session 是什麼？就是一種讓 Request 變成 stateful 的機制。以早餐店老闆娘的例子來說，Session 就是一種讓客人之間能互相關聯起來的機制。

## 如何在網路世界實作 Session 機制

上面的例子提到了可以用小紙條來記錄狀態，那在網路世界中可以靠什麼呢？

我們可以試試看利用網址! 利用網址來實作 Session 機制會像這樣子。

假設老闆娘的早餐店網站的網址是：breakfast.tw，當你第一次買帕尼尼的時候，你其實是送一個 Request 給伺服器，然後伺服器會把你導到 breakfast.tw?item=帕尼尼，之後你只要一直按結帳，都可以不用再選擇商品，而可以直接買到帕尼尼。

所以說，網址列上的 queryString 就是紙條，是儲存狀態的地方。

不過如果網址列又沒辦法儲存資訊太久，當瀏覽器重開儲存在網址列的狀態就通通消失了。

## 誰會隨身攜帶紙條

繼續早餐店的例子，如果每家店都用紙條的機制的話，每次出門前都要找對應商家紙條，這樣好像也沒有很方便餒!

幸好聰明的老闆娘想到了方法 - 把資訊存在手機裡頭! 手機大部分的人都會隨身帶著吧 (?

所有想要使用這個機制的老闆娘們合力開發了一個專屬 App，這個 App 把店家分門別類而且每個老闆娘只能看到自己儲存在客人手機裡的資訊。

![Imgur](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/3gKKkwZ.png)

老闆娘阿美可以從這個 App 看到你常點帕尼尼還有柳橙汁，可是她看不到從越南嫁過來開早餐店的阮大嬸在這個 App 寫的資料。

## 用 Cookie 實作 Session 機制

在瀏覽器中有一個像手機一樣的東西，我是指你平常會隨身帶著的這個特性。

每次發送 request 的時候，瀏覽器都會自動檢查 request 的網域有沒有存甚麼東西在 cookie 然後帶在 request header 裏頭。

使用 cookie 的好處是就算把瀏覽器關掉也沒有關係，cookie 還是會被存著，而且帶 cookie 這件事不用手動操作，是瀏覽器的規則，它會自己查找並帶上。

我們把瀏覽器與伺服器用紙條溝通的方式用 cookie 重新展示一次：

![Imgur](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/vMonO2K.png)

回到早餐店的案例，老闆娘愛上了這種方式! 因為這個 App 不只可以存常買品項而已。

某天老闆娘想到買兩杯大冰奶第二杯半價的活動，不過因為喝兩杯大冰奶根本會烙賽到不行，所以老闆娘善解人意(?的推出了寄杯的服務，至於剩餘的寄杯杯數老闆娘打算就放在 App 裡面。

![Imgur](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/Y0igfOG.png)

一個月以後，老闆娘對帳時發現這個月收了 100 杯大冰奶的錢，可是卻賣出了 1000 杯大冰奶!!!

很明顯的，有好多人、或者某個貪小便宜的人，把 App 裡的寄杯杯數竄改了。

## 發給客人專屬身分認證碼

既然 App 是灌在客人的手機上的，很難防止客人去動裡面的資料，聰明的老闆娘想到一個辦法，就是把 App 裡頭的資料給加密。

可是每次都還要用金鑰解密一次，老闆娘覺得有點麻煩，而且她再也不相信人性了，她怕哪天金鑰被偷了加密法也被破解怎麼辦?

於是老闆娘繼續思考，忽然她靈機一動! 「既然存在手機上的資訊會被竄改，那我把資訊存在我這邊不就好了嗎？」她的腦海閃過這個想法。

於是她集合了所有早餐店的老闆娘重新將這個 App 更新為 2.0 版本!

![Imgur](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/T27VYMo.png)

這一次 App 裡面每個店家只存了一個 QR Code，當老闆娘掃了自己的店家的 QR Code 的時候可以得知會員的流水號，注意這個流水號是一組隨機亂數。

透過這個流水號老闆娘可以在自己的資料庫找出這個會員常買的東西、還剩幾杯寄杯的大冰奶 ...

下圖是老闆娘的資料庫一隅：

![Imgur](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/fszIf8H.png)

最後我們再回到網路的例子，cookie 搭配身分認證碼實作上就是只讓 cookie 存 sessionId，當 request 與 sessionId 一併被送出的時候 Server 便可以透過 SessionId 來查找資料。

![Imgur](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/coTMVm3.png)

## 小實戰 - PHP 中的 session 機制

舉例來說，有一個留言板在登入後，server 會給瀏覽器一組 ID，然後在背後的資料庫裡在這組 ID 後面紀錄使用者名稱。

在處理登入的頁面 (handle_login.php)，server 請瀏覽器設置 cookie （一組 ssid）

![img](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/qhtDl0D.jpg)

server 的資料庫以 ssid 為名建立檔案並存入相關資訊（這裡以使用者名稱為例），注意這是 php 實作的方式而已。

![img](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/2IuvMKk.jpg)

導到主畫面以後，瀏覽器便帶著 cookie 這個 header，裡面的內容包含 ssid

![img](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/nVBmFcZ.jpg)

cookie 的內容包含 key 還有 value，也設定了在甚麼 domain 瀏覽器應該要帶上這個 cookie

![img](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/jh59Eu4.jpg)

最後想補充一下，其實不是所有的實際的資料都會存放在 server 端的資料庫，像是紀錄目前所在的分頁的話，就適合直接存在瀏覽器的 cookie 裡。


