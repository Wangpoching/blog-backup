# LEMP Stack 架站筆記

LEMP 是 Linux / Nginx / MySQL / PHP-FPM 的組合，跟 LAMP 不同的是沒有一鍵安裝包，要一個一個手動裝。

```
LAMP：Linux + Apache + MySQL + PHP
LEMP：Linux + Nginx  + MySQL + PHP-FPM
```

因為 Nginx 本身不能直接執行 PHP，所以需要透過 **PHP-FPM**（FastCGI Process Manager）來處理 PHP 請求：

```
Client → Nginx → PHP-FPM → PHP 網站
```

---

## 安裝 MySQL

```bash
sudo apt install mysql-server
```

> `mysql-client` 只能連線到別的地方的 MySQL，`mysql-server` 才會在這台主機上跑一個真正的資料庫伺服器。

### 設定 MySQL root 密碼

MySQL 安裝後，root 預設使用 `auth_socket` 驗證（靠 Linux 系統身份登入，不需要密碼）。為了增加安全性，我們要把驗證方式改成密碼登入。

用 root 登入，並切換到 mysql 系統資料庫：

```bash
sudo mysql -u root mysql
```

把 root 的驗證方式從 `auth_socket` 改成 `mysql_native_password`（密碼驗證）：

```sql
UPDATE user SET plugin='mysql_native_password' WHERE User='root';
```

> ⚠️ 這一步只改了硬碟上的資料，MySQL 記憶體裡還是舊的設定。MySQL 在運作中為了效能，永遠只讀記憶體而不是硬碟，所以必須下 `FLUSH PRIVILEGES` 強制讓記憶體更新，確保後續 `mysql_secure_installation` 連進來時，看到的是已經更新的驗證方式，才能正確設定密碼。

```sql
FLUSH PRIVILEGES;
exit;
```

執行安全性設定腳本，在這一步才會真正設定 root 的密碼：

```bash
sudo mysql_secure_installation
```

`mysql_secure_installation` 是 MySQL 官方提供的安全性設定腳本，會一步一步問你要不要修掉預設的危險設定：

| 問題 | 建議 |
|------|------|
| 設定密碼強度驗證 | Y，選 1（MEDIUM） |
| 設定 root 密碼 | Y |
| 刪除 anonymous 使用者 | Y |
| 禁止 root 遠端登入 | Y |
| 刪除 test 資料庫 | Y |
| 重新載入權限 | Y |

如果腳本跳過了設定 root 密碼這一步，顯示：

```
Skipping password set for root as authentication with auth_socket is used by default.
```

代表 plugin 還沒改成功，手動設定：

```sql
ALTER USER 'root'@'localhost' IDENTIFIED BY '你的密碼';
FLUSH PRIVILEGES;
```

---

## 安裝 phpMyAdmin

```bash
sudo apt install phpmyadmin
```

安裝過程中選擇 web server 的畫面，因為我們用的是 Nginx，選單裡沒有 Nginx 的選項，**兩個都不要選**，直接按 Ok 跳過，之後手動設定 Nginx config。

安裝完成後會出現以下警告：

```
Job for apache2.service failed because the control process exited with error code.
(98)Address already in use: AH00072: make_sock: could not bind to address [::]:80
(98)Address already in use: AH00072: make_sock: could not bind to address 0.0.0.0:80
no listening sockets available, shutting down
```

原因是 phpMyAdmin 安裝時順便裝了 Apache，但 port 80 已經被 Nginx 佔用，所以 Apache 無法啟動。不需要 Apache，直接停掉即可：

```bash
sudo systemctl stop apache2
sudo systemctl disable apache2
```

phpMyAdmin 的檔案安裝在：

```bash
/usr/share/phpmyadmin
```

這就很像在本機 XAMPP 的 `htdocs` 下面開一個 `phpmyadmin` 資料夾，只是 Nginx 不像 Apache 會自動去找這個資料夾，所以需要手動設定 config。

---

## 安裝 PHP-FPM

phpMyAdmin 安裝時會順便把 PHP CLI 裝進來，但還需要 PHP-FPM 讓 Nginx 能跑 PHP：

```bash
sudo apt install php7.4-fpm
```

安裝完會看到：

```
NOTICE: Not enabling PHP 7.4 FPM by default.
NOTICE: You are seeing this message because you have apache2 package installed.
```

因為系統偵測到有 Apache，所以沒有自動啟動，要手動啟動：

```bash
sudo systemctl start php7.4-fpm
sudo systemctl enable php7.4-fpm
sudo systemctl status php7.4-fpm  # 確認有在跑
```

---

## 設定 Nginx

Nginx 的設定檔放在 `/etc/nginx/`，有兩個重要資料夾：

```
sites-available/   ← 真實的 config 檔案放這裡
sites-enabled/     ← symbolic link 指向 sites-available
```

Nginx 實際上只讀 `sites-enabled` 裡面的設定，想停用某個網站只需要刪掉 link，不用刪掉真實的 config。

### phpMyAdmin 的 Nginx config

```bash
sudo nano /etc/nginx/sites-available/phpmyadmin
```

```nginx
server {
    listen 80;
    server_name 你的IP;

    location /phpmyadmin {
        root /usr/share/;
        index index.php index.html index.htm;

        location ~ ^/phpmyadmin/(.+\.php)$ {
            try_files $uri =404;
            root /usr/share/;
            fastcgi_pass unix:/run/php/php7.4-fpm.sock;
            fastcgi_index index.php;
            include fastcgi_params;
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        }

        location ~* ^/phpmyadmin/(.+\.(jpg|jpeg|gif|css|png|js|ico|html|xml|txt))$ {
            root /usr/share/;
        }
    }
}
```

### PHP 專案的 Nginx config

```bash
sudo nano /etc/nginx/sites-available/comment-board
```

```nginx
server {
    listen 443 ssl http2;
    server_name comment-board.bocyun.tw;

    root /var/www/html/comment-board;
    index index.php index.html index.htm;

    ssl_certificate     /etc/nginx/ssl/origin.pem;
    ssl_certificate_key /etc/nginx/ssl/origin.key;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;

    location / {
        try_files $uri $uri/ =404;
    }

    # 把 .php 請求轉給 PHP-FPM 處理
    location ~ \.php$ {
        try_files $uri =404;
        fastcgi_pass unix:/run/php/php7.4-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }
}
```

`fastcgi_pass unix:/run/php/php7.4-fpm.sock;` 是關鍵，告訴 Nginx 把 `.php` 請求丟給 PHP-FPM 的 socket 處理。

### 啟用 config 並重新載入

```bash
# 建立 symbolic link
sudo ln -s /etc/nginx/sites-available/comment-board /etc/nginx/sites-enabled/

# 測試語法有沒有問題
sudo nginx -t

# 重新載入（不中斷現有連線）
sudo systemctl reload nginx
```

---

## 部署 PHP 專案

把專案放到 `/var/www/html/` 底下，然後建立資料庫並匯入 schema：

```bash
# 登入 MySQL 建立資料庫
mysql -u root -p
```

```sql
CREATE DATABASE board;
exit;
```

```bash
# 匯入 schema
mysql -u root -p board < /var/www/html/comment-board/schema.sql
```

### MariaDB 與 MySQL 的相容性問題

本機如果是 MariaDB，AWS 上是 MySQL，`date` 類型不能用 `current_timestamp()`，要改成 `datetime`：

```sql
-- 原本（MariaDB 可以，MySQL 不行）
`startedAt` date NOT NULL DEFAULT current_timestamp(),

-- 改成
`startedAt` datetime NOT NULL DEFAULT current_timestamp(),
```

### 記得建立 conn.php 和 config.php

這兩個檔案通常不會放進 Git（因為有帳號密碼），要在 AWS 上手動建立：

```bash
cp conn.example.php conn.php
cp config.example.php config.php
sudo nano conn.php   # 填入資料庫帳號密碼
```

---

## 常用指令

```bash
# 查看 Nginx 錯誤日誌
sudo tail -f /var/log/nginx/error.log

# 管理服務
sudo systemctl status nginx
sudo systemctl restart nginx
sudo systemctl reload nginx   # 不中斷連線，只重新載入設定

# git 遇到 dubious ownership 錯誤
git config --global --add safe.directory /var/www/html/專案名稱
```

### 從本機匯出資料庫結構

```bash
# 在 Windows 上要切到 XAMPP 的 mysql bin 資料夾
cd C:\xampp\mysql\bin
mysqldump -u root -p --no-data 資料庫名稱 > schema.sql
```

`--no-data` 只匯出結構，不匯出資料，適合放到 Git 上讓別人參考。
