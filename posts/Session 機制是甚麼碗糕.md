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

補充一下，其實不是所有的實際的資料都會存放在 server 端的資料庫，像是紀錄目前所在的分頁的話，就適合直接存在瀏覽器的 cookie 裡。

## Cookie-based Session、Hash 與 JWT
還記得老闆娘有想過要把大冰奶的寄杯數量給放在客人的手機裡然後加密起來讓客人沒辦法隨意修改嗎? 但是當資料很多很長的時候加密過後的資料也很長，除此之外，客人在手機上也沒辦法看到自己到底寄了幾杯大冰奶，真的很讓人困擾欸。

我們回到老闆娘會給客人紙條寫上還剩下幾杯大冰奶寄杯的時候。

老闆娘已經領教了竄改紙條資訊的客人的教訓了。
這時候小明來買了五杯大冰奶然後全部寄杯，老闆娘一樣給了小明一張紙條寫上：
```
客人: 小明
寄杯數量: 5
```
只不過這次老闆娘神秘兮兮地在紙條右下角寫上了 85。

小明回家以後把紙條上的寄杯數字加了一個 0 改成了 50 杯。
「欸嘿嘿嘿」，只是加了一個 0 肯定不會被發現的嘻嘻。

但當小明隔了一個禮拜去早餐店領寄盃的時候，只見老闆娘拿筆算了一算。
「操你媽唬爛王!」老闆娘暴怒。

![img](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/jwt.jpg)

為甚麼小明會被抓到呢? 其實秘密就在右下角的神祕數字裡。
事實上老闆娘把寄杯的數字動了一些手腳:

> 寄杯數 × 秘密數字，然後只取後兩位

小明寄了五杯，5 × 37 = 185 → 取後兩位 → 角落寫 85。

小明把 5 改成 50，角落還是 85。但老闆娘一算：50 × 37 = 1850，後兩位是 50，跟角落的 85 完全對不上，馬上知道被動過了！

### Cookie-based Session
前面講的 Session 機制，是把 Session 資料存在 Server 端，Cookie 只存一個隨機的 SessionId。但其實還有另一種做法。

第一種變體叫做 **Cookie-based Session**：與其在 Server 端維護一張大表，不如直接把所有的 Session 資料加密之後塞進 Cookie 裡，這樣 Server 就不需要儲存任何東西了。

要特別釐清的是，「用 Cookie 存 SessionId」跟「Cookie-based Session」是不同的兩件事：

|  | 用 Cookie 存 SessionId | Cookie-based Session |
|---|---|---|
| Cookie 存什麼 | 一組隨機 ID | 加密過的完整資料 |
| 資料放在哪 | Server 的資料庫 | Client 的 Cookie |
| 主要風險 | SessionId 被盜用 | 加密金鑰被破解 |

缺點也很明顯，Cookie 本身有大小限制（通常是 4KB），存越多東西就越容易超過。

### 那 Hash 呢？

有人可能會想：既然 Hash 可以把任何長度的東西壓縮成固定長度，是不是可以解決大小問題？

其實不行，因為 Hash 跟加密是不同的東西：

- **加密**是雙向的，加密後可以解密，所以 Server 讀得回原始資料
- **Hash** 是單向的，無法從 Hash 值反推原始資料

所以 Hash 在這裡沒辦法拿來「儲存資料」，但它可以拿來做**防竄改驗證**——這就帶出了 JWT 的概念。

### JWT（JSON Web Token）

JWT 是一種常見的標準格式，長相大概像這樣：
```
eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoxMjN9.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c
```

它其實是三段用 `.` 分開的 base64 字串：
```
Header . Payload . Signature
```

- **Header**：說明用了哪種演算法
- **Payload**：實際資料，比如 `{ user_id: 123 }`（明文，只是 base64 編碼，**並非加密**）
- **Signature**：用密鑰對前兩段做 HMAC Hash，產生的簽章

當 Server 收到 JWT，會重新算一次 Signature，然後比對是否一致，就能知道資料有沒有被竄改。

所以 JWT 的重點不是「讓你看不懂資料」，而是「讓你沒辦法偷偷改資料」。因此不要把敏感資訊直接放在 Payload 裡，因為任何人 base64 decode 就看得到了。

你發現了嗎? 其實老闆娘在寄杯的紙條右下角寫的神祕數字其實就是 jwtToken 裡面的 Signature。

## 總結

| 機制 | 資料存放位置 | Cookie / Token 內容 |
|---|---|---|
| Session-based | Server | SessionId |
| Cookie-based Session | Client | 加密後的 Session 資料 |
| JWT | Client | Token（Payload + Signature） |

簡單來說：

- **Session**：Server 記住資料，Cookie 只存 ID  
- **Cookie-based Session**：資料加密後存在 Cookie  
- **JWT**：資料公開但不可竄改，用簽章驗證

最核心的目的其實只有一個：

> **讓原本 stateless 的 HTTP，可以辨識「同一個使用者」。**