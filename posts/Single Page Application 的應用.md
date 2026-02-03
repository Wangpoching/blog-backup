---
title: Single Page Application 的應用
---

Single Page Application 簡稱 SPA，在 web 的世界裡，SPA 指的是一種網頁架構。

從字面上可以看的出來，這種網頁架構主要只有一個單一頁面。在傳統的 MVC 架構底下，整個網站可能包含建立、讀取、修改、刪除頁面，當使用者進行一個功能，頁面會跳轉到處理那個功能的網頁。

可能會好奇是透過怎麼樣的技術去實現 SPA 的呢？**AJAX 技術**是推動 SPA 的一大功臣，透過 AJAX，瀏覽器的 JavaScript 可以從 Server 端獲得 **JSON 或者 XML 格式的純資料**，JavaScript 再去**動態渲染**這些純資料到網頁上，如此一來，便可以達成所有功能都在同一個頁面上的功能了。

## SPA 的優缺點為何

SPA 最大的優點莫過於**使用者的體驗**了，因為在多分頁的網站裡，每個畫面跳轉都要重新載入整個 HTML，如果使用 SPA 的網站，網頁會動態更新，而不會出現整個畫面消失的過程。**桌面應用程式一樣的使用感**對使用者體驗是革命性的提升。

其他的好處還有像是前後端的分工更加明確，後端只負責提供資料與計算，前端全權負責畫面的呈現。

但是 SPA 也有伴隨而來的缺點，最大的缺點可能就是 SEO ( 搜尋引擎最佳化 ) 問題了，因為大部分畫面渲染的功能都寫在 JavaScript 裡，一開始後端提供的 Single Page 可能幾乎只有骨架，那麼搜尋引擎在瀏覽 HTML 時便無法找到相關資訊，除非搜尋引擎連帶參考執行 JavaScript 程式碼才有可能解決。

### Multiple Page

下面的圖呈現了 Multiple Page 的網站架構。

![img](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/gpapGpK.png)

可以注意到每次要做刪除或是新增的動作，瀏覽器都會發出一個 request，然後 Server 會返回一個 html 讓瀏覽器跳轉，甚至可能再送出請求導回首頁的請求，如此一來，網頁又要再跳轉一次回到首頁，看看這個新增還有刪除的案例，在 Multiple Page 的架構下，可能會跳轉 4 次！

### Single Page

下面的圖呈現了 Single Page 的網站架構。

![img](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/VoxTUbH.png)

這一次除了一開始的進入首頁跟 Multiple Page 一樣，之後的功能都是發出 Ajax，在新增以及刪除的功能裡，Sever 只要回傳簡單的 ok 訊息，瀏覽器上的 JavaScript 便將首頁上的資料進行新增或刪除，如果是發出拿資料的 Ajax，此時 Server 只要單純回傳要取得的資料即可，而不用回傳完整的 HTML。注意一下，在圖片的案例裡，沒有經過任何跳轉，只有 JavaScript 動態修改首頁的元素而已。




