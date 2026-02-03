---
title: 當我們在 Google 搜尋時，發生了甚麼事？
---

當我們在 google 上搜尋「xxx外遇」，是否會好奇背後發生了甚麼事呢？ 

首先瀏覽器應該要先知道 google.com 這個 domain 的 IP 位址，所以會去問 DNS sever，中華電信的 DNS Server IP 位置通常是 168.95.1.1 或是 168.95.192.1，Google 也有提供免費的 DNS Server，IP 位置是 8.8.8.8， Cloudflare 的位置是 1.1.1.1。

不過既然我們都已經在 google 的首頁輸入關鍵字了，難道我們不知道 google.com 的 IP 位址嗎？ 答案是有可能知道也有可能不知道。在瀏覽器本身有 DNS cache，瀏覽器會先檢查這個快取裡有沒有 google.com 的 IP，如果有的話，便發送 request，那如果沒有呢？

別擔心，例如 chrome 有以 C 語言寫成的程式，比如說 `gethostbyname` 函式會呼叫作業系統檢查瀏覽器的 DNS cache 有沒有 google.com 的 IP，有的話便告知瀏覽器，沒有的話便送出 request 到 dns sever，解析出 IP 位址再告知瀏覽器。

**這邊小小的總結一下，瀏覽器本身不會是發送 request 給 dns sever 的主體，它在知道 IP 位址以後負責送 request 到正確的 IP 位址。**

如果寫成流程：
1. 瀏覽器送出關鍵字「xxx外遇」到 google.com
2. 瀏覽器檢查 dns cache 有沒有 google.com
3. 如果有的話直接發送 request 給 google.com 的 IP位址；沒有的話呼叫 C 語言提供的函式（比如 gethostbyname）
4. C 語言呼叫作業系統檢查 dns cache 有沒有 google.com 的 IP 位址，有的話回傳位址，
沒有的話去 DNS Server（8.8.8.8）問 google.com 的 IP位址
5. DNS Server（8.8.8.8）回傳 IP 位址
6. 瀏覽器發送 request 
7. Google server 收到資料，去資料庫查詢關鍵字，把搜尋結果回傳
8. 瀏覽器顯示搜尋結果