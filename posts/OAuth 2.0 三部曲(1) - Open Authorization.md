---
title: OAuth 2.0 三部曲(1) - Open Authorization
---

## 前言

OAuth 2 適用於**第三方開放授權**的協議，這個協議規範了使用者如果通過第三方授權來讓應用程式可以取得**使用者的資訊或是代表使用者採取某些行動**。

為甚麼會想要寫這個研究主題? 主要是因為這一年來的專案都要用到第三方登入，第三方登入應該是 OAuth2 最常使用到的場合了呢~ 既然這麼常用也就順便看一下它的規範以及為甚麼會有這樣的演化吧!

| ![2023文博會 登入頁面](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/97bf218888fad928.png) | 
|:--:| 
| *圖 1. 2023文博會 登入頁面* |

## 遠古時代 - 在 OAuth 協議之前
在最遠古的時候，使用者需要先向應用程式出示帳號以及密碼，應用程式接著再拿著這組帳號密碼代表使用者採取行動。

各位有想到那些問題呢? 可以先用筆寫下來再越過防雷線來看~

----- 
----- 
----- 
----- 
----- 

**我是防雷線**

----- 
----- 
----- 
----- 
-----  

下面是筆者給出的答案:
1. 應用程式必須明碼儲存使用者的帳密
2. 應用程式有使用者的帳密可以代表使用者做任何事
4. 一旦其中一個應用程式被破解會導致使用該帳號密碼的資料都被破解

仔細思考可以發現問題在於應用程式一但拿到使用者的帳密根本就等於是使用者本人了，如果是這樣的話也就是說不能直接把帳密交給應用程式，那該怎麼解呢?

| ![在 OAuth 之前的第三方授權流程](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/ad5072f2a3f04e48.png) | 
|:--:| 
| *圖 2. 在 OAuth 之前的第三方授權流程* |

## OAuth2: 來個授權伺服器吧!

聰明的人們決定引入一個中間層，這個中間層可以接收使用者的帳密，也可以讓應用程式在上面註冊並明訂要以使用者的名義做的事情以及範圍。

如此一來，應用程式不僅不用直接拿使用者的帳密，而且也可以定義清楚應用程式想要存取的權限範圍。

下面我們來看看在 OAuth2 協議裡面的各個行動者吧!

* Resource User: 使用者(擁有帳密的人)
* Client: 應用程式
* User Agent: 使用者代理人(通常指瀏覽器)
* AccessToken: 身分令牌，可以拿來存取使用者的資源
* RefreshToken: 更新令牌，生存時間比身分令牌長，當身分令牌過期時可以拿更新令牌換取新的身分令牌
* Authorization Server: 授權伺服器，負責核發存取令牌和更新授權令牌，同時也讓應用程式在其上註冊並開通存取權限的範圍
* Resource Server: 資源伺服器，存放使用者的資源

其實最重要的就是 Authorization Server 了，他是應用程式還有使用者的裁判(?，由它來統一進行`驗證/發放`授權。

下友會介紹四個 OAuth2 的認證模式，但不管是哪個模式，都有 Authorization Server 的存在~


### AuthorizationCode Grant Flow (授權碼模式)

這是一種最安全的方式。應用程式不直接向使用者要求許可，而是透過授權伺服器轉址的方式在轉回應用程式時夾帶授權碼給應用程式，應用程式再使用授權碼取得存取令牌，用授權令牌可以獲取受保護的資料。

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/776ff7ad3c556c53.png)

這個流程讀者們可能會覺得拿 AuthorizationCode 換 AccessToken 怎麼這麼雞肋，為甚麼不直接給 AccessToken 就好，不過再仔細看看流程就會知道 AuthorizationCode 是在重新導向的時候夾帶的，如果是 AccessToken 被截獲就一切都拜拜了。

再注意到最後一個流程，Client 最後將 AuthrizationCode 還要再加上 secret 證明自己才可以拿到 AccessToken，這一步驟通常是在後端進行，所以不僅 AccessToken 不會外流而且 secret 也只要一直儲存在後端即可。

第二種認證流程就差在這裡，差別在於要不要拿 AuthorizationCode 換 AccessToken。


### Implicit Grant Flow (隱含授權模式)

承上面所說的，隱含授權模式就差在要不要走 AuthorizationCode 這一步，如果不走的話就是直接在重新導向的時候把 AccessToken 帶回來囉!? 這樣好像就沒後端甚麼事了耶! 

那通常是甚麼場景會用到這種模式呢?

隱含授權模式適用於前端 Web 應用程式，也就是在瀏覽器內執行 JavaScript 的應用程式。這類應用程式會使用 JavaScript 存取伺服器資源(通常是 WebAPI)，再更新頁面上的資訊。例如 :
Gmail 會依據使用者點選的收件匣的訊息，更新頁面上顯示的資訊，而不需要整頁重新導向(如果想要在瀏覽器直接拿到 AccessToken 的話)。

可是因為這個流程 AccessToken 存在瀏覽器，外露的風險大，所以在隱含授權模式裡面就不可以拿 RefreshToken 去更新 AccessToken。

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/c147ec6c798a125e.png)


### Resource OwnerPassword Credentials Grant Flow (密碼模式)

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/2701b0b286c4bf4a.png)

疑，這個流程怎麼跟最古老的那個模式好像阿! 的確他們有 8 成都一樣，但差別還是在應用程式必須在一開始向授權伺服器註冊自己，以及最後仍必須向授權伺服器取得 AccessToken 才能獲取資源。

不過這樣子古早古早的缺陷他不是都有嗎? 沒錯! 因為使用者在輸入帳號密碼時並不是在第三方的頁面，也就是說**他可能無法知道或決定自己的那些資源將可以被取用**，除此之外，也有帳密被應用程式存起來的風險。

所以說，到底是甚麼情況適合這種授權模式呢? 通常會用在使用者高度依賴的應用程式，例如 **作業系統內建的應用程式**或是**官方應用程式**。

### Client Credentials Grant Flow (憑證模式)

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/66f5c7369b54b8b3.png)

最後這東西看起來流程怎麼這麼簡易呢!? 因為其實這個情況是應用程式本身就是使用者的情況! 應用程式通常屬於後端應用沒有前端參與。

## 結語

下一篇會用寄信系統的案例介紹 **AuthorizationCode Grant Flow (授權碼模式)** 的實作，希望各位讀者可以在透過實際的案例對 OAuth 的流程以及應用場景有更高的掌握。

想知道 OAuth2.0 如何用在 gmail 寄信功能的讀者可以接著看[這一篇](https://lidemy5thwbc.coderbridge.io/2024/04/06/nodemailer/)






