---
title: MVC 架構 - 以 express 為例
---

MVC 架構是一種軟體的設計模式，在軟體開發裡面十分重視 seperation of concerns，把整個應用程式拆成許多獨立的模組，彼此分工合作，而 MVC 架構是一種分離模組的方式。

首先先看一下簡略的架構圖，說明 express 如何使用 MVC 如何處理一個 request 並傳送 response。

![img](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/7vvb2lx.png)

### Model

當應用程式想要做「刪除/新增/修改/瀏覽」的動作，需要與資料庫互動，這時候會有一個物件 (Model 物件）與資料庫連動，當用 javascript 對這個物件做新增、刪除的動作時也會連動到資料庫。

MVC 裡的 Model 層負責管理 Model 物件，通常會寫下一些商業邏輯，舉例來說，會員購物打折，或者是超過一定的金額免運費等等。這些獨立於網頁介面的商業邏輯，或者說產品邏輯，會寫在 Model 層裡。

### View

View 負責管理畫面呈現，也就是 HTML 樣板 (template)。在實際的情況中，因為畫面可能會呈現動態的資料，所以會進一步使用樣板引擎 (tempalte engine)，來放入動態的資料。

### Controller

request 會先被送到 Controller，再由 Controller 通知 Model 調度資料，資料接著被傳遞給 View 來產生樣板 (template)，並將呈現資料的 HTML 頁面回傳給客戶端。

此外，有關應用程式本身的邏輯問題，通常會由 Controller 來控制，比如說
* 使用者是否要先登入才能看到網頁內容?
* 誰只能閱讀資料，但不能修改和刪除

Controller 會設置許多不同的路徑，當收到 get/post/delete 或是收到不同路由就會引發後續一系列的動作。

最後讓我們再看回架構圖，當一個 request 被送進來，會先送到 Controller，根據路由以及動作來觸發 Controller 上的開關。之後可能牽涉到 Controller 先檢查是否登入，如果有登入便呼叫 Model 從資料庫拿取資料，Controller 接著把資料送給 html template engine ，最後 Controller 把 html 當作 response 回傳給使用者。



