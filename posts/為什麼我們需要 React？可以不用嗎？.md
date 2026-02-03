---
title: 為什麼我們需要 React？可以不用嗎？
---

## **前言**

就像 jQuery 曾經當紅一時一樣，前端框架或函式庫的出現是為了解決一些不方便，jQuery 是一套 JavaScript 的函式庫，它的重點在於支援跨瀏覽器操作 DOM。那是一個瀏覽器百家爭鳴的年代，各個瀏覽器提供操作 DOM 的方法有些並不一致，在這樣的情況下使得 jQuery 成為當紅炸子雞。 

當瀏覽器漸漸大一統以後，前端開發者們依舊面臨著一些難題，起因於我們往往要因為資料的變化而進行許多取得 DOM 或者變更 DOM 的操作，這主要會造成兩個問題。

1. 網頁規模大且複雜時，事件的管理、資料的變化和關係等都變得複雜，導致維護和 Debug 上越來越困難。
2. 當資料面變化後，在更新到頁面上時，容易造成不必要的頁面更新。

而 React 這個前端框架可以幫助使用者解決上面的兩個問題，所以這也是 React 目前方興未艾的原因。

## **React 的特色**

### **不用直接操作 DOM**

不論使用瀏覽器原生的 API 操作 DOM 或者是 jQuery，都稱作 **Imperative programming**，
但這樣子的情況容易產生上面提到的缺點，也就是當網頁功能及架構變大及複雜時，會越來越難掌握事件及衍伸的狀態變化，程式碼也容易雜亂無章。

有鑑於此，React 採用的是 `Declarative programming`，我們只要讓 React 知道資料的狀態以及資料如何放進頁面裡，React 會替使用者在資料變動時進行更新 DOM 的操作。如此一來，不僅容易維護程式碼，也可以降低在網頁元素複雜時出現該更新的元素忘記更新的情況。

比如說像下面的範例，我們定義一個代辦事項，當我們想要更改代辦事項的時候，只要將 todo 的 content 內容更新，便可以達到 `document.querySelector('.todo-content').innerHTML = xxx` 的效果。 採用 `Declarative programming` 時使用者只需要很直觀的更新資料而不用操作 DOM，這就是 React 的功勞。

```jsx
let todo = {
  id: id.current,
  isDone: false,
  content: value,
  isShow: true
}

function Todo() {
  return (
    <Content>{todo.content}</Content>}
    <Buttons>
      <EditButton
        type="button"
        onClick={() => {
          if (isEditMode) return
          handleChangeMode()
        }}
      > 
      </EditButton>
      <DeleteButton type="button" onClick={handleDeleteTodo}> 
      </DeleteButton>
    </Buttons>
  )
}

```

這個時候 React 這個命名便顯得有些傳神了，因為 React 可以**及時反映資料的變化在頁面上**。

### **打造可以被重複利用的元件**

React 也可以讓我們能輕鬆打造可以被重複利用的元件。 這些元件可以在不同的地方被重複使用，比如說很多網站都會有的 Hamburger Menu。

這樣的好處在於我們可以很好的在網頁各處達到一致性的更新，而不用同樣的程式碼，在專案中的多處重複書寫。

### **單一方向的資料流**

在使用 React 的時候，當我們希望頁面有所變更時，使用的狀態資料就必須更新——這就是所謂的**單一方向的資料流**。

舉例來說，當使用者點擊了一個按鈕，React 會攔截並看看該做什麼。假設我們在此時改變資料的狀態，React 便會根據新的狀態，結合元件，更新 DOM。

下圖以新增代辦事項來說明，動作-資料-畫面的關係。

![img](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/kNylcyU.png)

這樣的好處可以讓我們在 Debug 時容易許多。因為我們只需要關注**資料存在何處，以及資料往哪個地方流去**。而不會發生資料更改，但忘記同步更新 DOM 的窘境。

### Virtual DOM

剛剛提到單一方向的資料流，也就是說當資料改變了，React 便會將頁面重新渲染，然而資料在哪個部分被改變了沒有被納入考慮。

一樣以 Todo List 的例子來說明，假設目前 Todo List 上有 100 個代辦事項，現在我們想要加入一個代辦事項「清理房子」，結果 React 在發現資料更新以後，將這 101 個資料全都重新繪製了一遍。

假如我們不使用 React，可能會使用類似 `parentNode.append(xxx)` 的語法，這樣的狀況下只要在 DOM 上面新增一個元素即可，效能上似乎比使用 React 好了許多。幸好 React 使用了 VirtualDOM 的概念來解決這個問題。

首先，當渲染一個 React App 時，會將 DOM 先複製成一份 JavaScript 物件，而這也就是 VirtualDOM。當資料變化時，會將更新後的結果複製一份新的 VirtualDOM 出來。

最後，React 會拿新舊 VirtualDOM 進行比對，並將有差異的地方到實體的 DOM 中進行更新**這樣的優化過程就是所謂的 reconciliation**。 

下圖展示了 VirtualDOM 到 實際 DOM 的繪製流程（紅色代表更新的部分）。

![img](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/Umwj6u8.png)

## **總結**

總的來說，當我們透過 React 在開發時，可以很輕鬆的只關注在資料的管理，因為最後 React 會在背後為我們進行最有效率的 DOM 操作與更新。此外，因為組件可以拆分，讓我們不論在維護專案或是開發新專案都十分方便。

如果再回到前言觀察裡面提到的兩個問題：

1. 網頁規模大且複雜時，事件的管理、資料的變化和關係等都變得複雜，導致維護和 Debug 上越來越困難。
2. 當資料面變化後，在更新到頁面上時，容易造成不必要的頁面更新。

便可以發現都可以透過 React 順利解決!但可不可以不要用 React，當然也是可行的。