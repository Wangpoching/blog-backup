---
title: OAuth2.0 三部曲(3) - OPENID CONNECT(OIDC) 身分認證機制 
---

## 前言
前面有說到，OAuth 主要用來讓用戶授權，那如果是專門想做身分驗證的用途呢? 想當然也是可以的，只要用戶授權讓 Client 可以取得用戶資訊，比如說 `email` 或者`身份證字號`，便可以利用這些唯一資訊來創建以及識別用戶。

不過有一點著實令人頭痛，如果用戶的 email 在第三方認證機構是可以修改的怎麼辦? 又或者我們拿著這些資料存到資料庫裡，為了要登入，這些資訊在資料庫裏面也不能編輯。

所以如果能有一組 token 是綁定用戶的唯一值便太完美了! 因為這個 token 除了識別沒有其他意義所以他不需要被修改，第三方認證機構提供這個 token，client 將這個 token 作為識別用戶的唯一識別碼。 這便是 OPENID CONNECT(之後簡稱 OIDC) 想做的事。

## ODIC 標準
![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/58ef7dd71ceb669c.png)
讓我們稍微來談談 OIDC 有甚麼好處，想像一下，如果進入每個網站都要重新註冊很令人望之卻步對吧? 如果我們能使用 Social Login 登入便可以不用記憶這麼多組密碼。 除此之外，你肯定也更放心在這些傳統而有信譽(? 的大機構底下輸入你的個人資訊以及密碼吧?

OIDC 也可以大幅降低維運的風險及成本。怎麼說呢？過去習於要求使用者自負使用服務的資安風險，所以會有很多亂七八糟的密碼規則限制用戶。而今資安的責任逐漸轉移至服務提供者，一個代表性的指標就是 NIST 新版的 800–63 號 [《電子驗證指導原則》](https://dl.acm.org/doi/book/10.5555/2206278)。在這份文件中，要求服務提供者不應對用戶施加密碼規則，而是要求服務端以各種方式抵擋密碼外洩及設計抵抗暴力破解的機制。說起來容易，要抵禦變化多端的攻擊手法對營運商是一大考驗。所以藉由 OIDC 委外認證，對用戶及服務提供者都更有保障，如果密碼外洩都不是我家的事。

## ODIC 機制
所以說 ODIC 跟 OAuth2.0 有甚麼不一樣?
OAuth2.0 是一種授權機制，而 ODIC 則是認證機制，我們可以利用授權機制來達到認證機制。』ˊ這也便是為甚麼 ODIC 其實是奠基於 OAuth2.0 之上的。

首先我們來複習一下 OAuth2.0 中的 AuthorizationCode 流程:
![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/776ff7ad3c556c53.png)

那麼我們現在來看到 ODIC 的 Flow
![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/908d67ad1862aa3c.png)

注意到紅色的地方是比原先 OAuth2.0 的 authorizaton code 模式差異的部分
* 步驟 (A) 的 Scope 選擇 `openid`
* 步驟 (E) 會取回 `id_token` 以及 accessToken
* 步驟 (F) 有一個提供`更詳細用戶資訊的 API` 可以用 accessToken 取得

所以說那個可以拿來當作唯一識別碼的東西在哪?

其實 id_token 是一個 JWT WebToken，所以我們試著把它解碼

## ODIC vs OAuth2.0
既然 ODIC 是奠基於 OAuth2.0 之上，我們來細數它新增的部分。

ID Token：認證所需的用戶資訊。而 Access Token 是用於授權，不帶有用戶資訊來做認證。

UserInfo API：除了上面 ID Token 提供基本用戶資訊，OIDC 還規定認證提供者應提供一個 API 界面，讓 Client 能取的更完整的用戶資訊。(步驟 E)

Standard Set of Scopes：OAuth 2.0 沒有定義 scope， Facebook 可能叫 email，Google 可能叫 mail...，實做的時候必須參閱各家的手冊客製化。OIDC 則規範了共同的 scope 。

## DEMO
最後我們來實作一個 Line Login 使用 ODIC Flow。
1. 在 [Line Developers](https://developers.line.biz/) 創建一個 Line Login 的應用 
![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/09d26f53114d9821.png)
2. 將 callBack Url 改為 https://oidcdebugger.com/debug
![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/b3b2e26240e2e0eb.png)
3. 開啟 [OpenID Connect debugger](https://oidcdebugger.com/)。Authorize URL 填入 https://access.line.me/oauth2/v2.1/authorize 而 Client ID 填入 LINE Login Channel ID。最後 Send Request
![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/c7091923b9f5ee2e.png)
![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/ad2d47b276de8de0.png)
4. 這個時候應該會導轉到 Line 的登入頁面，可以注意有一個 302 導轉的 http Status Code，再輸入帳號密碼的頁面會提醒將允許讓 Client 存取`用戶識別資訊`
![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/7f472b0dca74be5d.png)
5. 恭喜~ 這個時候應該會回到 redirect_uri 的介面並取得 authorizationCode。
![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/23c5ccc0d242345e.png)
6. 接著我們還是要用 authorizationCode 取得 accessToken。這一段請用 postman 或是 curl 打 API。

```
POST https://access.line.me/oauth2/v2.1/token
Content-Type: application/x-www-form-urlencoded
 
grant_type=authorization_code&
code=rQSvNyNGXGJT9uaNoip7&
client_id=2005466252&
client_secret={clientSecret}&
redirect_uri=https%3A%2F%2Foidcdebugger.com%2Fdebug
```

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/d278e78f85d3eeac.png)

最後我們把 id_token 這個 JWT WebToken 給解碼以後:
其中 iss 代表這是由 LINE 發出的使用者識別資訊，sub 是這個用戶在 LINE 的唯一識別 ID，`兩者連接起來就是用戶在網路上唯一的識別 ID`。
![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/cfaaac371b5d853d.png)

## 結語
OAuth2.0 的三部曲到這裡告一段落了，希望大家之後在 OAuth2.0 做授權時可以重新思考過整個架構，如果沒有將 ODIC 導入做第三方登入也非常建議試試看喔!










