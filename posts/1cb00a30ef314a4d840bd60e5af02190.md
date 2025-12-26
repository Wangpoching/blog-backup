---
title: OAuth2.0 三部曲(2) - 使用 nodemailer 幫忙寄信
---

[OAuth2.0 概念介紹](https://lidemy5thwbc.coderbridge.io/2024/02/01/oauth-20/) 還沒看過這一篇的讀者可以先看看這篇
## 事前準備
在開始之前 可以先到[這裡](https://github.com/Wangpoching/nodemailer/tree/master)把程式碼下載下來~

### 在 Google Cloud Platform 申請 GMAIL 服務
#### 創建專案
* 首先到 [google cloud platform](https://cloud.google.com/)
![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/225136a0f40b82d6.png)
* 登入以後創建新專案
![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/db5c8ef04ce41e0d.png)
* 自己選個合適的名稱並建立專案
![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/ebdd068be08f728f.png)
* 這個時候在專案總列表應該就可以發現它了
#### 啟用 Gmail API
![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/98095f7e19a4159b.png)
* 現在你要決定這個專案想要啟用 google 提供的哪些服務，在這個案例裡面是 gmail，也就是說在後面 OAuth 的流程裡面我們拿到的 accessToken 只能用來串接 gmail 的服務喔!

點一下左邊漢堡選單，然後點選「已啟用的 API 和服務」
![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/bc956589afe9476f.png)
* +啟用 API 和服務
![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/fcbe6322dd2e1011.png)
* 尋「Gmail API」，然後點選「Gmail API」
![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/89eea864cc7e4c1b.png)
* 啟用
![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/74ccbead43b19b98.png)
#### 設定 OAuth 同意畫面
* 現在要先設定 OAuth 的同意畫面，就是讓使用者輸入 google 的帳密然後告知使用者即將授權給應用程式甚麼權限的那一頁~
回到「API 和服務」，然後點選「OAuth 同意畫面」
![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/89270e40f20232a4.png)
* 選擇「外部」，然後點選「建立」
![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/b52a6a7bb829dd0f.png)
* 然後把資料填一填，不過這邊的應用程式名稱是會在 OAuth 授權頁面被使用者看到的喔! 仔細想想要怎麼命名吧~
![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/55e6eb79123d9f13.png)
* 這邊可以直接跳過
![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/baf9d4ecfc88d334.png)
* 最後如果是測試版的話可以輸入一些電子郵件，只有這些電子郵件可以授權給應用程式
![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/d0d4504979d2f49e.png)

#### 建立憑證
最後的最後我們需要建立憑證，因為在程式碼裡面我們不可能登入 google cloud platform 來證明我們是**應用程式管理者本人**，但我們可以建立一組憑證，既然只有應用程式管理者本人才能建立憑證，所以如果在程式碼裡面塞入正確的憑證即可代表是應用程式管理者本人。
* 回到「憑證」的頁面，然後點選「建立憑證」，接著點選「OAuth 用戶端 ID」
![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/4b185c860c3277dc.png)
* 在應用程式類型欄位選擇「網路應用程式」，然後輸入以下欄位：
名稱：自己取名
已授權的重新導向 URI：請輸入 http://localhost:3000/auth/google/callback
![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/72b2900aada3fd06.png)
* 這個時候就可以拿到 CLIENT ID 以及密鑰了，把這些都存起來，然後不要外流，外流的話其他應用程式就可以打著你的名義跟其他使用者索取授權囉~
![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/11794f594d82bbd7.png)

### 建立環境

* 先在跟目錄的 .env 資料夾把 CLITNT_ID 以及 CLIENT_SECRET 換成你剛剛申請好的那一組，如此一來 dotenv 會幫你把他們給載入環境變數

```.env
CLIENT_ID=你的 Client ID
CLIENT_SECRET=你的 Client Secret
REDIRECT_URI=http://localhost:3000/auth/google/callback
```

* 接著再根目錄創建名稱為 config 的資料夾，然後在裡面建立一個檔案，名稱為 googleOAuth2Client.js，這個檔案提供一個 compile 好的 googleOAuth2Client，它可以幫忙諸如**導到 google 授權頁面**、**導轉回拿取 authorizationCode 的頁面**、**索取 accessToken**、**利用 accessToken 打 goole API 來取得對應的服務**...... 等功能

```
require('dotenv').config();

const { google } = require('googleapis');

const googleOAuth2Client = new google.auth.OAuth2(
  process.env.CLIENT_ID,
  process.env.CLIENT_SECRET,
  process.env.REDIRECT_URI
);

module.exports = googleOAuth2Client;
```

* 接著我們利用 bootstrap 快速建立發信頁面

```
<!DOCTYPE html>
<html>
  <head>
    <title><%= title %></title>
    <link rel='stylesheet' href='/stylesheets/style.css' />
    <link rel='stylesheet' href='https://cdnjs.cloudflare.com/ajax/libs/bootstrap/5.3.0/css/bootstrap.css' integrity='sha512-lp6wLpq/o3UVdgb9txVgXUTsvs0Fj1YfelAbza2Kl/aQHbNnfTYPMLiQRvy3i+3IigMby34mtcvcrh31U50nRw==' crossorigin='anonymous'/>
  </head>
  <body>
    <h1><%= title %></h1>
    <p>Welcome to <%= title %></p>

    <form method="post" action="/email/user/send">
      <div class="mb-3">
        <label for="exampleInputEmail1" class="form-label">Email address</label>
        <input type="email" class="form-control" id="exampleInputEmail1" name="email" aria-describedby="emailHelp">
        <div id="emailHelp" class="form-text">We'll never share your email with anyone else.</div>
      </div>
      <div class="mb-3">
        <label for="exampleInputSubject1" class="form-label">Subject</label>
        <input class="form-control" id="exampleInputSubject1" name="subject">
      </div>
      <div class="mb-3">
        <label for="exampleInputContent1" class="form-label">Content</label>
        <textarea class="form-control" id="exampleInputContent1" name="content" rows="5"></textarea>
      </div>
      <div class="mb-3 form-check">
        <input type="checkbox" class="form-check-input" id="exampleCheck1">
        <label class="form-check-label" for="exampleCheck1">Check me out</label>
      </div>
      <button type="submit" class="btn btn-primary">Submit</button>
    </form>

    <!-- Popup Modal -->
    <% if (status === 'success') { %>
      <!-- Popup Modal -->
      <div class="modal" id="statusPopup" tabindex="-1">
        <div class="modal-dialog">
          <div class="modal-content">
            <div class="modal-header">
              <h5 class="modal-title">Status Message</h5>
              <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body">
              <!-- Place your success message here -->
              <p id="statusMessage">Email sent successfully!</p>
            </div>
          </div>
        </div>
      </div>
      <script src="https://cdnjs.cloudflare.com/ajax/libs/bootstrap/5.3.0/js/bootstrap.bundle.min.js" crossorigin="anonymous"></script>
      <!-- Script to show the modal -->
      <script>
        var statusPopup = new bootstrap.Modal(document.getElementById('statusPopup'));
        statusPopup.show();
      </script>
    <% } %>
  </body>
</html>

```

這邊如果是有帶 status 參數的話會跳出一個彈窗表示發信的狀態，會在送信完以後用 ?status=xxx 的 queryString 形式帶回發信頁面 (因為筆者很懶所以不想再多寫一頁XD)

* 接著把目光移到授權的路由這裡 **routes/auth.js**

```
var express = require('express');
var router = express.Router();

const googleOAuth2Client = require('../config/googleOAuth2Client');

const SCOPES = [
  'https://mail.google.com/',
];

router.get('/login', (req, res) => {
  const authUrl = googleOAuth2Client.generateAuthUrl({
    access_type: 'offline',
    scope: SCOPES,
  });
  res.redirect(authUrl);
});

router.get('/google/callback', async (req, res) => {
  const code = req.query.code;
  try {
    const { tokens } = await googleOAuth2Client.getToken(code)
    googleOAuth2Client.setCredentials(tokens);
    req.session.tokens = tokens;

    res.redirect('/email/user');
  } catch (err) {
    console.error('Error authenticating with Google:', err);
    res.status(500).send('Error authenticating with Google');
  }
});

module.exports = router;
```

login 頁面我們利用 googleOAuth2Client.generateAuthUrl 幫我們創造 google 授權頁面的路由，然後再導轉過去。

google/callback 頁面則負責處理從 goole 送回來的 accessToken，我們會把它存進 cookie 裡面，這樣後面在發信的時候就可以拿出來用，存好以後導轉到首頁。

* 最後是首頁以及寄信的路由 **routes/email.js**

```
var express = require('express');
var router = express.Router();
const nodemailer = require('nodemailer');

/* GET home page. */
router.get('/user', function(req, res, next) {
  res.render('index', { title: 'Mailer', status: req.query.status });
});

router.post('/user/send', (req, res) => {
  const {
    refresh_token,
    access_token,
  } = req.session.tokens;
 

  const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
      type: 'OAuth2',
      user: 'wangpeter588@gmail.com',
      clientId: process.env.CLIENT_ID,
      clientSecret: process.env.CLIENT_SECRET,
      refreshToken: refresh_token,
      accessToken: access_token,
    },
  });

  const mailOptions = {
    from: 'wangpeter588@gmail.com',
    to: req.body.email,
    subject: req.body.subject,
    text: req.body.content,
  };

  transporter.sendMail(mailOptions, (err, info) => {
    if (err) {
      console.error(err);
      res.status(500).send('Error sending email');
    } else {
      console.log(info);
      res.redirect('/email/user?status=success');
    }
  });
});

module.exports = router;
```

user 頁面就是首頁，ejs 會 render 提供使用者輸入寄信信箱、主旨以及內介面，同時也負責提醒寄信的狀態。

[POST] user/send 則透過 user 頁面的 form 表單觸發，利用 nodemailer 寄信，參數需要的 accessToken 由 session 取得，而 CLIENT_ID、CLIENT_SECRET 則由環境變數取得。

## 成果展示
![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/3957202b37fd8072.gif)

## 結語
之所以用 nodemailer 展示 OAuth2.0 的實作就是因為想讓讀者知道 OAuth2.0 實作場景並不僅僅侷限在第三方登入，因為 OAuth2.0 實際上是一個**授權協定**，除了授權拿取個資做第三方登入之外也可以拿來寄信、甚至 geocoding 等等......

接著會講到最後一個 OAuth2.0 的小延伸「OpenID」，先小暴雷一下 OpenID 就是基於 OAuth2.0 的技術下專門做第三方登入服務的架構呢!