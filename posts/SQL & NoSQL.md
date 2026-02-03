---
title: SQL & NoSQL
---


## NoSQL 跟 SQL 的差別在哪裡？

### 簡介

SQL (Structured Query Language) 是一種處理關聯式資料庫的語言，而相對於關聯式資料庫，NoSQL (Not Only SQL)泛指非關聯式的資料庫。

首先來比較一下關聯式資料庫與非關聯式資料庫的差別。

<table>
  <tr>
    <td></td>
    <td>SQL</td>
    <td>noSQL</td>
  </tr>
  <tr>
    <td>適用場合</td>
    <td>交易性以及高度一致性的線上交易處理、線上分析處理</td>
    <td>低延遲應用程式的各式各樣資料存取</td>
  </tr>
  <tr>
    <td>資料結構</td>
    <td>嚴謹定義的欄位結構以及與其他資料表的關係</td>
    <td>彈性的資料結構，包括鍵值、文件和圖形等等</td>
  </tr>
  <tr>
    <td>ACID</td>
    <td>可以遵守 ACID</td>
    <td>鬆綁 ACID 模型，來達到能夠橫向擴展的更彈性化資料模型</td>
  </tr>
  <tr>
    <td>效能提升</td>
    <td>針對資料表結構優化</td>
    <td>基礎硬體大小、網路延遲</td>
  </tr>
  <tr>
    <td>拓展</td>
    <td>增加硬體運算能力</td>
    <td>可以分割，透過分散式架構來向外擴展</td>
  </tr>
  <tr>
    <td>API</td>
    <td>符合結構式查詢語言 (SQL) 的查詢</td>
    <td>以物件為基礎的 API</td>
  </tr>
</table>

### 應用實例

#### 關聯式資料庫

假設我們要從關聯式資料庫 Book 找一本叫`制服女孩`的書，資料庫長得像下面這樣：

<table>
  <tr>
    <td>ID</td>
    <td>Author</td>
    <td>Year</td>
    <td>Title</td>
  </tr>
  <tr>
    <td>1</td>
    <td>史旺基</td>
    <td>2014</td>
    <td>制服女孩</td>
  </tr>
  <tr>
    <td>2</td>
    <td>珍.奧斯汀</td>
    <td>2019</td>
    <td>福爾摩斯小姐.貝克街的淑女偵探</td>
  </tr>
  <tr>
    <td>3</td>
    <td>馬克.弗雷利</td>
    <td>2021</td>
    <td>密碼的故事</td>
  </tr>
</table>

```
SELECT Title, Year FROM book WHERE title = '制服女孩'
```
#### 非關聯式資料庫

假設有一個使用 JSON 實作的 Book 資料表長得像下面這樣。

```
[
    {
        "year" : 2014,
        "title" : "制服女孩",
        "info" : {
            "genres" : ["寫真", "高中"],
            "photographer" : "史旺基"
        }
    },
    {
        "year": 2021,
        "title": "密碼的故事",
        "info": {
            "grand": "xxx大獎",
            "rating": 8.9
        }
    }
]
```



可以看到 NoSQL 可以很彈性的存取每本書的資訊。使用 AWS 的 DynamoDB 可以透過比對 key 的方式回傳書籍資訊，比如想找尋 title 是制服女孩的書。

```
import boto3
from boto3.dynamodb.conditions import Key

dynamodb = boto3.resource('dynamodb', endpoint_url='http://localhost:8000')
table = dynamodb.Table('Book')
response = table.query(KeyConditionExpression=Key('title').eq('制服女孩'))
for book in response['Items']:
        print(book['title'])
```

## 資料庫的 ACID 是什麼？

### 交易 (Transaction)

在上面提到 SQL 以及 NoSQL 的比較提到了 ACID，這裡就來介紹 ACID。

在關聯式資料庫裡常常將資料異動的最小單位稱為一筆**交易 (Transaction)**，舉個簡單的例子，在購物網站的資料庫，顧客下訂了一份巴斯克乳酪蛋糕，有三件事要做。

1. 先檢查還有沒有蛋糕，沒蛋糕就結束
2. 有的話蛋糕的數量 -1
3. 顧客的購物車裡加上一個蛋糕

我們開始思考有甚麼規則是必須遵守的，首先這三個動作**要都成功，要不然就都失敗**，想像一下，如果步驟 2 成功了，但步驟 3 失敗了，店家認為的蛋糕數量就會比實際上少一個，等到發現的時候，蛋糕可能就壞掉了。

### Atomicity（ 原子性 ）

這也就是在一筆交易中要保持 **Atomicity（ 原子性 ）**，每一筆交易中只有兩種可能發生，第一種是全部完成 (commit)，第二種是全部不完成 (rollback)。

### Consistency（ 一致性 ）

第二個特性是 **Consistency（ 一致性 ）**，當錯誤發生，所有已更改的資料或狀態將會恢復至交易之前，相信這件事很好理解。

### Isolation（ 隔離性 ）

再來思考一下如果這個巴斯克乳酪蛋糕是超級搶手的限時商品，這時候會發生甚麼情況呢? 大量的訂單可能會同時湧入，就可能會發生 race condition 的情況。至於甚麼是 race condition 呢?

假設現在蛋糕只剩一個了，有兩筆時間非常接近的訂單湧入，我們來預估事件可能發生的情況。

第一筆訂單檢查蛋糕數量剩下一個，所以準備執行下一個動作
|
第二筆訂單檢查蛋糕數量剩下一個，所以準備執行下一個動作
|
第一筆訂單執行把蛋糕數量 -1 ，此時庫存顯示為 0
|
第二筆訂單執行把蛋糕數量 -1 ，此時庫存顯示為 -1
|
第一位客人的購物車放進一個蛋糕
|
第二位客人的購物車放進一個蛋糕

如果畫成簡易的圖大概會像這樣：

--->--->--->
 --->--->--->

發現問題了嗎? 所謂的 race condition 就是指一個系統或者進程的輸出依賴於不受控制的事件出現順序。在這個搶購案例裡就出現的超賣的窘境。

要怎麼解決這個問題呢?如果在**多筆交易同時進行時，未完成的交易資料並不會被其他交易使用，直到該筆交易完成**，這樣就可以解決這個問題了。

而這也就是所謂的 Isolation（ 隔離性 ）。

### Durability（ 持續性 ）

最後這個特性雖然感覺有點雞肋但還是很重要的，我們必須保證**交易完成後對資料的修改是永久性的，資料不會因為系統重啟或錯誤而改變**。也就是所謂的 Durability ( 持續性 ）。

## 什麼是資料庫的 lock？為什麼我們需要 lock？

剛剛提到在關聯式資料庫資料的異動是以 Transaction 為單位進行的，而每筆交易要保持 ACID 的特性。這邊我們來實作搶購系統的案例來實際演示一下。

### 搶購系統

我們在 mysql 建一個名叫 product 的資料表，裡面有一個庫存 3 的商品。

![img](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/Tsj4I4K.jpg)

接著寫一個很陽春的搶購頁面。

```
<?php

require_once('conn.php');

$stmt = $conn->prepare("SELECT amount from products where id = 1");
$stmt->execute();
$result = $stmt->get_result();
if ($result->num_rows > 0) {
  $row = $result->fetch_assoc();
  echo "amount" . $row['amount'];

  if ($row['amount'] > 0) {
    $stmt = $conn->prepare("UPDATE products SET amount = amount - 1 where id = 1");
    if ($stmt->execute()) {
      echo '購買成功';
    }
  }
}
$conn->close();

?>
```
這個頁面會先檢查有沒有庫存，如果有的話就印出庫存數量，接著將資料庫內的庫存數量減 1，然後印出購買成功。

我們連續進入搶購頁面，看到庫存從 3->2->1->0 ，然後維持 0，沒有任何問題。

![img](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/ikQfQsi.png)
![img](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/xzrZPUV.png)
![img](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/DTgSfYR.png)
![img](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/lFDoe31.png)
![img](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/48SJgKR.png)

但如果一次有大量的人進入搶購頁面呢? 為了模擬這個情形，使用 jmeter 軟體來進行模擬。關於 jmeter 的安裝可以參考[這裡](https://www.tpisoftware.com/tpu/articleDetails/1705)。

先把資料庫裡的庫存數量調成 1

![img](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/duvtjZJ.png)

接著進入 jmeter 設定 10 的執行緒，延遲 0 秒。

![img](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/YA6ILIT.png)

設定要送出的請求內容，開始執行。

![img](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/2X5XO2k.png)

結果我們發現其中一個 request 竟然回傳 amount: -7，也就是說，10 筆 request 裡面竟然賣出了 8 筆，原來這就是 race condition。
明明只有一個庫存卻賣出了 8 個。

![img](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/YR5Lo61.png)

### lock 鎖

該怎麼辦呢? 回憶剛剛提到的 Transaction 提到的 ACID 特質，這個時候如果利用 Isolation 的特性來鎖住特定的 row，等一筆交易結束後才開鎖就可以解決了。所以我們修改一下搶購頁面的程式碼：

```
<?php

require_once('conn.php');

$conn->autocommit(FALSE);
$conn->begin_transaction();
$stmt = $conn->prepare("SELECT amount from products where id = 1 for update");
$stmt->execute();
$result = $stmt->get_result();
if ($result->num_rows > 0) {
  $row = $result->fetch_assoc();
  echo "amount" . $row['amount'];

  if ($row['amount'] > 0) {
    $stmt = $conn->prepare("UPDATE products SET amount = amount - 1 where id = 1");
    if ($stmt->execute()) {
      echo '購買成功';
    }
  }
}
$conn->commit();
$conn->close();

?>
```

首先要把 autocommit 設定成 false，防止每次呼叫 excute 後就會執行 sql 語法。接著開啟一個 Transaction ，把動作都寫進 Transaction 裡，最後再 commit Transaction。

這樣一來

1.檢查有沒有庫存，如果有的話就印出庫存數量，沒庫存就結束
2.將資料庫內的庫存數量減 1
3.印出購買成功

就被包裝成一個 Transaction 了，自然也就具備了 Isolation（ 隔離性 ）。

等等，眼尖的你可能發現修改過的程式碼多了一個`for update`

```
$stmt = $conn->prepare("UPDATE products SET amount = amount - 1 where id = 1");
```

這是甚麼意思呢? 在 MySQL 的 InnoDB 中，預設的 Tansaction isolation level 是 REPEATABLE READ（可重讀）。雖然不能更新或刪除，但是超賣的問題就是因為沒有鎖住 row 的讀取而造成的。

SELECT 的讀取鎖定可以使用 for update，這樣一來在交易 (Transaction) 進行當中 SELECT 到同一個數據表時，都必須等待其它交易被提交 (Commit) 後才會執行。

那麼來測試新的搶購頁面，把庫存調回 1，把 jmeter 的設定改成造訪新的搶購頁面來執行。

最後應該可以從結果樹看到只有一筆交易會成功!

