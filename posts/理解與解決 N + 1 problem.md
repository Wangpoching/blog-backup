---
title: 理解與解決 N + 1 problem
---

N + 1 問題涉及到後端效能的問題，很多人可能都聽過，如果沒聽過也沒關係，這篇文章會試圖用比喻的方式模擬 N + 1 問題，並以 sequelize 為例，看看要如何解決這樣的問題。

## 我想做一個提拉米蘇

今天忽然心血來潮想做一個提拉米蘇，想像這樣子的情境：冰箱在儲藏室裡、食譜在書房裡、而你在廚房準備要做提拉米蘇。

首先，你到書房拿了製作提拉米蘇的食譜，並且將它帶到廚房。

你閱讀食譜的第一行：

`馬斯卡彭乳酪 250g`

於是你去儲藏室的冰箱拿出 250 克的馬斯卡彭乳酪。

接著你閱讀食譜的第二行：

`鮮奶油 100ml`

於是你去儲藏室的冰箱拿出 100 毫升的鮮奶油。

最後你閱讀食譜的第三行：

`手指餅乾 10 根`

於是你去儲藏室拿出 10 根手指餅乾。

這樣子來來回回在廚房與儲藏室之間真是讓你累壞了，**其實你正在體驗的，就是 N + 1 problem** 你的 ORM 被迫要在你拿到食譜以後再多做 N 次的查詢 (去儲藏室拿食材 N 趟）。

## 實際案例

現在有一個食譜網站長得像這樣。

巧克力蛋糕     | 蘋果派    | 麵包 
--------------|----------|------    
黑巧克力 200 克|蘋果 4 個  |麵粉 300 克
蛋 3 顆       |蛋黃 1 顆  |水 300 毫升 
奶油 100 克   |奶油 100 克|鹽 1 茶匙
麵粉 50 克    |麵粉 50 克 |麵糰 100 克
糖 100 克     |糖 100 克  |

背後涉及到了兩個 model，分別是 Recipe 以及 Content
Recipe 的每一列記錄了成品的名稱，比如說蘋果派或是麵包；而 Content 的第一欄則以 recipe-name 紀錄對應到的成品名稱，並且記錄了材料的名稱以及數量，比如說：

recipe-name | name    | amount
巧克力蛋糕   | 黑巧克力 | 200 克

所以說**一筆 Recipe 擁有多筆 Content，而一筆 Content 則屬於一筆 Recipe**。

如果是用 express + sequelize 寫的網站，可能會寫這樣的 Controller：

```
// 拿食譜
const recipes = await Recipe.findAll()
const contents = []
// 拿材料
for (const recipe of recipes) {
    const content = await awesomeCaptain.getContents()
    ingredients.push(content)
}
```
食譜上有三種料理，為了把這種料理的食譜給呈現在網站上，我們總共必須造訪資料庫 4 次，**一次拿出整本食譜，另外三次拿出三種料理要用到的食材。**

## 如何解決

我們可以造訪資料庫一次就好嗎? 如果可以在資料庫裏面**把 content 給 join 到 recipe** 便沒問題了，就好像是**在書房拿到食譜以後，先不回廚房，而是先去閣樓的冰箱把食譜上載明要用到的食材都一起拿到廚房去**。

這個動作有一個專有名詞叫做 `eager loading`，以 sequelize 為例，可以將剛剛的程式碼改寫為：
```
// 拿食譜與材料
const recipes = await Recipe.findAll({
    include: Content
})
```

相對於 eager loading 則是 lazy `loading`，當然不是每次都要使用 eager loading，但如果需要或取關聯資料，使用 lazy loading 就好像自己製造了一場 DDoS 的攻擊呢(笑

使用 sequelize 的讀者可以參考 [sequelize 的官方文件](https://sequelize.org/master/manual/assocs.html#lazy-loading-example) 有更多關於 include 的進階用法。














