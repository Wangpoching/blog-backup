---
title: 如何用 Nginx 伺服器代理 express 程式
---

### 前言 - 代理伺服器

之前使用過 apache 搭配 php 寫的後台，現在開始利用 nodejs express 寫後端，又遇到了要架伺服器的時候了，express 比較特別的地方在於，有別於 php 是利用檔案系統來當作路由，**express 的路由是自定義的**，下面是一個取自[express 官方](https://expressjs.com/zh-tw/starter/hello-world.html)的小範例。

```js
const express = require('express')
const app = express()
const port = 3000

app.get('/', (req, res) => {
  res.send('Hello World!')
})

app.listen(port, () => {
  console.log(`Example app listening at http://localhost:${port}`)
})
```

可以看到程式碼中設定了 '/' 的路由，會顯示 'Hello World'，另外值得注意的是 port = 3000 這一行，代表這個 express app 是監聽 3000 埠(ㄅㄨˋ)號的，也就是說一支 express 程式其實就是一支後台程式了。

為了方便不同網站之間的管理，通常會將不同網站的程式碼分開寫成不同的 express app，分別交給不同的 port 監聽，因為 **一個 port 只能被一支後台程式占用**。

假設現在我們寫了兩支程式，分別交給 port 3001 以及 3002 監聽，並且把域名 example.tw 給指向主機，這樣一來使用者必須輸入 `https://example.com:3001/` 以及 `https://example.com:3002/` 來獲取對應內容，但這樣很麻煩，誰會去記得 port 號碼呀!

如果在 http/https 專用的 80/443 port 架一台伺服器，然後透過不同的子網域讓這台伺服器把使用者的需求轉交給對應 port 上的伺服器就可以解決這個問題了。聽起來有點抽象，可以看看下面這張圖來了解。

![img](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/rHKWLjh.png)

可以看到 example.com 有兩個子網域 aaa.example 以及 bbb.example，使用者造訪這兩個子網域時，預設會讓 80/403 port 上的代理伺服器處理。代理伺服器裡的設定檔設定將 aaa.example.com 的請求送到 3001 port、將 bbb.example.com 的請求送到 3002 port，如此一來使用者便不用輸入埠號了，因為代理伺服器幫忙代勞了。

說了這麼多，這篇文章接下來會實際展示如何**在 ubuntu 作業系統上架設 Nginx (代理伺服器） + express 的系統**。

## 目錄

* **前言**
* **AWS EC2 主機架設**
* **Nginx 安裝與防火牆設定**
* **子網域設定 / Nginx 設定檔**
* **網頁資源搬遷**
* **AWS RDS mysql 資料庫架設**
* **安裝 express, sequelize**
* **連接 AWS RDS mysql 資料庫**
* **sequelize-cli 建立資料庫表格**
* **pm2 背景管理 express**

## AWS ECS 主機架設

關於 AWS EC2 的主機，在之前架設 APACHE + PHP 的伺服器就有跑過一次完整的流程，請參考[這裡](https://lidemy5thwbc.coderbridge.io/2021/07/27/webserver-set/)，在這次的範例裡，記得開啟 80、403 以及 443 port 的防火牆，分別給 http, https 以及 SSH 使用。

## Nginx 安裝與防火牆設定

在租好了 AWS EC2 主機之後先用 SSH 連進主機，在終端機輸入

```shell
ssh -i {金鑰地址} ubuntu@{IPv4}
```

接著先更新 apt 裡註冊的套件，然後下載 nginx ，在終端機輸入

```shell
sudo apt update
sudo apt install nginx
```

再來要設定主機的防火牆，在終端機輸入

```shell
sudo ufw app list
```

可以看到註冊在 ufw 底下的有這些設定檔

```
Available applications:
  Nginx Full
  Nginx HTTP
  Nginx HTTPS
  OpenSSH
```

接著把  Nginx Full 打開，這樣一來就可以允許 http/https 的請求，在終端機輸入

```shell
sudo ufw allow 'Nginx FULL'
```

最後要確認一下有沒有開啟 Nginx 服務，在終端機輸入

```shell
sudo systemctl status nginx
```

如果出現 `Active: inactive` 的內容，在終端機輸入

```shell
sudo systemctl start nginx
```
到這邊為止完成了基礎了 Nginx 架設。

這邊要補充一下為甚麼已經在 AWS EC2 的 security group 開啟了 80 以及 443 port，但是在 ec2 仍然要 sudo ufw allow 'Nginx FULL' 開啟 http 以及 https 的監聽，我們可以想像有**兩層** 防火牆，第一層是流量能不能進入 ec2 instance 的守門員，第二層才是進入 ec2 以後的防火牆呢!

## 子網域設定 / Nginx 設定檔

現在 80/403 port 已經由 Nginx 監聽，記得上面的代理伺服器架構圖嗎? 首先要在 DNS 設定  子網域，將子網域都先指向 EC2 的主機。

在 cloudFlare 上設定 DNS ，首先將網域（bocyun.tw）指向主機的 public IPv4，

![img](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/FWA6Yec.jpg)

接著設定 CNAME，將 blog.bocyun.tw 以及 getprize.bocyun.tw 設為 bocyun.tw 的別名，如此一來，當使用者對 blog.bocyun.tw / getprize.bocyun.tw 發起請求都會被視為對 bocyun.tw 發起請求，指向主機的 public IPv4。

![img](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/M6tWlOA.jpg)

![img](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/UsIBpzN.jpg)

到此為止不論是 bocyun.tw, blog.bocyun.tw 還是 getprize.bocyun.tw 都會被 80/443 port 的 Nginx 伺服器處理。最後一步要讓 Nginx 分別把 blog.bocyun.tw 以及 getprize.bocyun.tw 交給負責的 port 去處理。

在終端機輸入

```shell
cd /etc/nginx/
vim nginx.conf 
```
看看實際上 Nginx 在執行的時候會跑哪一些設定檔。

```
##
# Virtual Host Configs
##

include /etc/nginx/conf.d/*.conf;
include /etc/nginx/sites-enabled/*;
```

設定檔寫了會 include sites-enabled 所有的檔案以及 conf.d 底下附檔名是 conf 的檔案，因此我們決定在 sites-enabled 新增 configuration。

在終端機輸入 

```shell
cd sites-available/
```

等等，不是要到 sites-enabled 底下嗎? 這邊我們利用在 sites-available 下創建設定檔，再建立捷徑到 sites-enabled 的方式來進行。如果要暫時關閉服務，可以把捷徑先移除，不會去動到實際的設定檔，這就是設定捷徑的好處了。

先新增設定檔 blog.bocyun.tw ，在終端機輸入

```shell
sudo vim blog.bocyun.tw
```

在 blog.bocyun.tw 裡寫入(注意:備註不要真的寫出來!)

```
server {
     // 實際監聽的 port
     listen       80;
     // server 名稱
     server_name  blog.bocyun.tw;
     // 代理到的 port
     location / {
       proxy_pass http://127.0.0.1:5001;
     }
 }
```

再來記得要在 sites-enabled 底下建立捷徑，在終端機輸入

```shell
sudo ln -s /etc/nginx/sites-available/blog.bocyun.tw /etc/nginx/sites-enabled/
```

reload 設定檔，在終端機輸入

```shell
sudo systemctl reload nginx
```

把 getprize.bocyun.tw 也照做一次，這時候便完成了 Nginx 代理的功能。

## 網頁資源搬遷

架好後台系統以後可以開始把資源丟進去，先把資料夾的權限打開才可以寫入資源，在終端機輸入

```shell
sudo chown ubuntu /var/www/html
```

接著可以選擇使用 SFTP 傳輸，用 FileZilla 建立 SFTP 連線。

![img](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/lnxmoTe.jpg)

也可以直接用把 github 上的專案 clone 下來，在終端機輸入

```shell
git clone {repository 的網址}
```

## AWS RDS mysql 資料庫架設

靜態資源已經備妥，接著要連線到 mysql 資料庫，可以在主機上安裝 mysql 的程式，也可以連線到外部主機的 mysql，這次使用 AWS 提供的 RDS 來玩玩。

到AWS主控台，點選RDS服務。

![img](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/herhqzo.png)

點選 create database

![img](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/Kqy3HyY.png)

選擇 standard create，這樣可以自行設定。

![img](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/sau7NNC.png)

選擇 mysql （隨你開心）

![img](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/1CAjfyF.png)

選擇方案，這邊選擇 free tier

![img](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/dnLM7tD.png)

### 基本設定

進入基本設定，首先填入 RDS 的主機名稱，假設填入 database-1，之後這台有 mysql 資料庫主機的域名就會是 database-1xxxxx，但不是很重要，因為外面的人看不到。

還要填入一組使用者帳密，可以自行輸入或是讓隨機匹配一組。

![img](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/ORlolS3.png)

接著選主機的資源配置，抱歉因為剛剛選了 free tier ，現在只給選最陽春的。

![img](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/lRwxTel.jpg)

再來選儲存空間，因為怕被收費，所以就沒改預設。

![img](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/61uaesG.jpg)

### 連線設定

最後進入連線設定，快完成了!

首先設定 Virtual Private Cloud (VPC)，讓其他服務在這個虛擬網路中，只有透過在這個 VPC 中設定好的連線方式才能連接到服務。

然後在進階選項中的 Publicly accessible 選擇 Yes，這樣 VPC 以外的裝置也可以連線到這個資料庫，不過通常如果要安全一點，會把 EC2, RDS 放在同一個 VPS 下，然後拒絕 Publicly accessible。

![img](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/vH1BLeP.png)

DB 連線認證方式使用預設選項，也就是使用DB密碼即可連線。

![img](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/9Pr1zk6.jpg)

最後要注意看一下收費方式喔! 重點有 3 個
1. 一台 RDS instances 一個月上限運行 750 個小時（大概就是只能開一台不停機）
2. SSD 只有 20 GB 免費
3. 備份硬碟的容量只有 20 GB 免費

![img](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/ztxaiTh.jpg)

## 安裝 express, sequelize

資料庫有了，主機有了，可是還沒有 express 跟 sequelize，這樣子網頁跑不起來，所以接下來要在主機裝好 express 以及 sequelize。

首先要找到 [nodejs 的 binary file](https://github.com/nodesource/distributions)，在終端機輸入

```shell
curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
sudo apt-get install -y nodejs
```

檢查有沒有安裝成功，在終端機輸入

```shell
node -v
```

接著進到寫 express server 的資料夾，安裝 dependencies，在終端機輸入

```
npm install
```

## 連接 AWS RDS mysql 資料庫

再來要把主機連上前面創建好的 AWS RDS 資料庫，先到 AWS RDS 服務看創建好的資料庫的資訊。

![img](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/Hml1I0x.png)

接著到 security group 開啟 3306 port 的防火牆

![img](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/lHocAMC.png)

測試用 MySQL WorkBench 看有沒有辦法連線成功

![img](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/Bjc6L3Z.jpg)

測試成功以後，可以修改 express configuration 連線設定檔

![img](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/OXnDCSG.png)

## sequelize-cli 建立資料庫表格

但是現在資料庫還是空的，要利用 sequelize-cli 幫我們把 DB 內的資料庫以及表格建立起來。

在終端機輸入

```shell
npx sequelize-cli db:create
```

創建好資料庫以後，在終端機輸入

```shell
npx sequelize-cli db:migration
```

要注意的是不要一次執行全部的 migration 檔，打個比方，假設 B 表格有 foreign key 對到 A 表格，那麼如果先創建 B 表格就會失敗，所以要按照當初 migration 檔生成的順序一一執行。

## pm2 背景管理 express

最後如果要執行 express server，要執行 node {app.js} ，可是這樣有點麻煩，如果 cmd 的視窗被關掉，nodejs 就停止執行了，難道就不能像 Nginx 一樣在背景執行嗎? 

在 global 環境安裝 pm2，在終端機輸入

```shell
npm install pm2 -g
```

用 pm2 執行 js 檔，在終端機輸入

```shell
pm2 start {app.js}
```

要開兩個 sever 就輸入兩次，如果要檢查 pm2 上運行的程式，在終端機輸入

```shell
pm2 ls
```

![img](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/eA1c3RY.jpg)

要重開 / 重載入 / 暫停 / 殺掉 運行的程式，在終端機輸入
```
pm2 restart id
pm2 reload id
pm2 stop id
pm2 delete id
```

最後一點還滿重要的，因為是在背景運行，所以 nodejs 不會在 cmd 上報錯，在終端機輸入

```shell
pm2 logs
```
這樣就可以偵錯啦~

到此為止總算是完成 Nginx + express 的伺服器啦! 恭喜



















