---
title: Git 版本控制(下)
---

# 前言

今天老闆叫我 `把自己的 branch rebase development 的 branch`，我真的是完全看不懂啊! 不過在稍微研究一下以後，發現 rebase 其實和 merge 的目的其實是一樣的，有鑑於 Git 版本控制(上) 已經累積了太大的篇幅，所以接下來有關 Git 的整理會集中在本篇。

-----

-----

# merge vs. rebase

## 事前準備

首先創建一個資料夾並且開啟 git 版控

```bash
mkdir git_practice
cd git_practice
git init
```

接著創建一個 example.txt，在裡面寫上 `我是第一行`

```
vim example.txt
```

最後提交

```
git add example.txt
git commit -m "first commit"
```

--------------------------------------------

我們在 example.txt 再新增一行 `我是第二行`

然後提交

```
git add example.txt
git commit -am "second commit"
```

## 複習 merge

事前工作準備好了以後我們要來創造另外一個分支，並且**製造衝突**。

建立 task2 分支並進入。

```bash
git checkout -b task2
```

-----------------------------------------

我們在 example.txt 再新增一行 `我是 task2`

然後提交

```
git add example.txt
git commit -am "task2 commit"
```

-----------------------------------------

我們在 example.txt 再新增一行 `我是第三行`

然後提交

```
git add example.txt
git commit -am "third commit"
```

-----------------------------------

接著回到 task2 分支。

```bash
git checkout task2
```

-----------------------------------------

我們在 example.txt 再新增一行 `我是 task2 again`

然後提交

```
git add example.txt
git commit -am "task2 commit again"
```

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/origin.png)

### 合併

現在我們要合併 task2，會產生衝突

```bash
git checkout master
git merge task2
```

合併失敗了，我們打開 example.txt 解決衝突並存檔

最後再重新提交

```bash
git add example.txt
git commit -am "合併 task2"
```

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/Merge.png)

這裡可以注意到合併後的 commit 會以時間先後穿插 master 以及 task2 的 commit

## rebase

如果我們回到 merge 以前的狀態這次改採 rebase

現在我們切換到 task2 分支以後對 master 進行 rebase

```bash
git checkout task2
git rebase master
```

與 merge 的時候相同，我們一樣遇到了衝突無法合併的情況

我們打開 example.txt 來解決衝突並且存檔

接著把 rebase 的流程繼續做完

```bash
git add example.txt
git rebase --continue
```

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/Rebase.png)

如果不想 rebase 了記得要 `git rebase --abort`

這邊大家注意到幾件事:
1. Task2 的分支整條被拔起來重新放在 master 的最後面，這個動作就叫做 `renase`，意指請幫我重新從 master 長出來一次
2. task2 2 原來的版號都改變成新的了
3. 解決衝突以後沒有新增一個 commit

最後我們再切回到 master 去把已經 rebase 過的 task2 給合併進來:

```bash
git checkout master
git merge task2
```

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/Rebase_then_merge.png)

## rebase 的優劣

### 優點
* 不會在合併時產生多餘的 commit。
* 合併時會依分支的 commit 排列，能夠比較清楚的 review issue 或 feature 處理的過程。如果使用 merge，在合併後就會依照時間順序穿插排列兩個分支的 commit。
* 在貢獻開源專案的時候，如果在 push 前先做 rebase，那作者就能夠直接以 fast-forward 的方式合併，不需要再另外解衝突。

### 缺點
最大的缺點就是上方提到的，使用 rebase 會修改 commit 的歷史紀錄。


# git stash: 在工作區暫存檔案

工作中常常遇到這樣的問題~ 當你正在做一個大型功能時，有一個 bug 忽然跑出來 PM 要你緊急解掉。可是如果要切 branch 的話就要先把當前的改動 commit 才行 OAOO，這樣一個做一半的功能要 commit 也很怪，欸抖該怎麼辦呢?

在這之前想跟大家釐清 git 的幾個工作區的概念~
![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/dc1b60a90a49e5ac.png)

我們在改動檔案時，這些改動都存在於 working directory 裡面，接著我們告訴 git 這些改動準備要被提交了，這時候這些改動被存在 stage area 裡，當提交以後版本會記錄在 local repository 裡，local repository 則可以再推到 remote repository 裡頭。

上面提到的問題就聚焦在 working directory，那兩個藍色的指令:
```
git stash
git stash pop
```

它們的效用在於可以將 working directory 的改動暫存起來，如此一來便可以直接切換到其他 branch，因為 working directory 被清空了，暫存起來的改動同樣也可以釋放回 working directory 繼續編輯~


-----

## 實作

首先開啟 git 版控資料夾並在 example.txt 寫入 **Fist Line**
```
mkdir stashPractice
cd stashPractice
git init
touch example.txt
// 寫入 First Line
git add .
git commit -m "update example.txt"
```

-----

### 暫存檔案

現在在 example.txt 再加上 **temporary content......**
輸入下面的指令將改動暫存在工作區:
```
git stash
```
可以看到出現這樣的訊息: 
`Saved working directory and index state WIP on master: 593682f update example.txt`
代表已經成功暫存了~

這個時候再回去看 example.txt 發現內容只剩下:
`First Line`
這是因為 working directory 的改動已經被移動到暫存區囉~

-----

### 還原暫存

如果使用:
```
git stash pop
```
便可以把剛剛暫存的改動拉回 working directory~
所以這時候 example.txt 又回到:
`First Line`

`temporary content......`

-----

### 瀏覽 git stash 列表

每次 git stash 以後都會回到原本 commit 的狀態，我們總共做三次 stash，分別添加
`temporary content......`、
`temporary content 02` 以及
`temporary content 03`

這時候如果我們輸入:
```
git stash list
```
會發現有三行:
`stash@{0}: WIP on master: 593682f update example.txt`

`stash@{1}: WIP on master: 593682f update example.txt`

`stash@{2}: WIP on master: 593682f update example.txt`
stash@{0} 是最後暫存的，stash@{2} 則是最早暫存的。
git stash pop 會將最上面 (stash@{0}) 的暫存給還原，也就是說 git stash pop 會使得 example.txt 的內容變成:
`First Line`

`temporary content 03`

-----

### 清除暫存

使用
```
git stash drop
``` 
可以清除最新的暫存

使用
```
git stash clear
``` 
則可以清除全部的暫存

使用
```
git stash drop stash@{n}
``` 
可以清除指定的暫存

-----

### 補充

如果想要還原特定的暫存，也可以仿照刪除的手法使用:
```
git stash pop stash@{n}
```

-----
-----

# 補充: 在團隊協作中統一 commit 的樣式

由於最近開始在公司中與同事協作大型專案，便不能按照自己的風格隨意 commit，沒錯我就是亂 commit 的那一個人(笑，下面教各位讀者如何無痛整合專案成員的 commit 樣式 ~ !

## 寫一個有條不紊的 commit

![](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/2e7986fa04db6a63.png)

像這樣一個 Commit 裡面包含了 `Header` 與 `Body`，Header 不要超過一行，並且由 Type 以及 Subject 組合而成，Type 首先將 commit 的類型給分類； Subject 則試圖以扼要的文字總結 commit 做的事情；Body 可以多行，較為詳實的記錄了本次版本更新的內容。

依照 Angular 的規範，Type 有以下幾種:

feat: 新增/修改功能。
fix: 修補 bug。
docs: 文件 (documentation)。
style: 格式 (不影響程式碼運行 white-space, formatting, missing semi colons, etc)。
refactor: 重構。
perf: 改善效能。
test: 增加測試。
chore: 建構程序或輔助工具的變動 (maintain)。
revert: 撤銷回覆先前的 commit 例如：revert: type(scope): subject (回覆版本：xxxx)。

這樣一來，另一個閱讀的人便可以以不同的心態觀察程式碼，打個比方，如果 Type 是 Fix，可以用「觀察 Commit 如何解決錯誤」的角度來閱讀程式碼。

另外，建議`不要一次將所有改動 commit`，一次更新一個種類的 Type 並提交才可以讓 Commit 紀錄可以做好分類。

## git config

git config 是 Git 提供的一個管理和設定組態參數的工具。等等的教學會用上它，因此我們先來認識它一下~

Git 參數的組態設定分為三個層級:
1. 作業系統層級 (/etc/gitconfig)
2. 使用者層級 (~/.gitconfig)
3. 專案層級 (.git/config)

要調整系統層級的 config 要在參數帶上 `--system`、使用者層級要在參數帶上 `--global`、直接在專案內使用 git config 則會在專案層級設定。

Git 在查找組態時會由專案 > 使用者 > 作業系統層級依序查找。

## 開始實作

首先我們先創建一個空檔案準備存放 commit 的 template

```bash
touch .gitcommittemplate.txt
```

接著把這個檔案移動到目前使用者的根目錄下面

```bash
cp .gitcommittemplate.txt ~/.gitcommittemplate.txt
```

設定 git config 中 template 的位置(這邊也可以把層級設在使用者或是專案

```bash
git config --global commit.template ~/.gitcommittemplate.txt
```

為了確保 gitcommittemplate.txt 中的註解(#開頭的)也被寫進 commit message，這邊要再使用 git config 指令調整 commit 中的一些保留規則

```bash
git config --global commit.cleanup strip
```

strip 可以使得
`Strip leading and trailing empty lines, trailing whitespace, commentary and collapse consecutive empty lines.`

翻譯一下，設定 strip 可以刪除結尾與開頭的空白行、刪除每行末尾的空白、開頭帶有 # 的行，並且會把文中連續的空白行縮成一行空白。

最後打開 gitcommittemplate.txt

```
vim ~/.gitcommittemplate.txt
```

將 template 貼上

```
#git commit log
# <type>: <subject> {required}

# you need to give a blank line

# <body> {optional}

# <footer> {optional}

# <type>
# feat: 新功能
# fix: Bug修復
# docs: 文檔改變
# style: 代碼格式改變
# refactor: 功能重構
# perf: 性能優化
# test: 增加測試代碼
# build: 改變build工具
# ci: 與ci相關的設定
# add: 增加一些跟功能無關的檔案
# 3rd: 增加第三方
#
# <subject>
# 概括描述變動
#
# <body>
# 詳述改變內容，越詳細愈好
#
# <footer>
# 補充內容
```

這樣一來，下次在使用 git commit 的時候就可以直接用模板寫了(淚奔

上面的步驟如果很麻煩也可以寫成 bash 喔!













