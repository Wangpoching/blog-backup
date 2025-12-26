---
title: 淺談 Redux 的特性與資料流
---

# Redux 是什麼？可以簡介一下 Redux 的各個元件跟資料流嗎？

## Flux

在 Redux 被提出來以前，類似的概念是 Flux，Flux 提出了 Store 的概念。 在 React 裡，因為每個 Component 都有自己的 State，為了共用這些 State，造成了許多麻煩。

例如將 State 往上移到 Parent State，最後 Parent Component 擁有一堆 State。

這樣的方法的好壞見人見智，不過有些人覺得這樣子不太自然，因為他們認為 child 應該擁有自己的 State 才可以做到元件獨立化。

底下是從 [React Flux](https://zh-hant.reactjs.org/blog/2014/07/30/flux-actions-and-the-dispatcher.html) 擷取的 Flux 資料流。

![img](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/vse3Db3.png)

我們可以看到存放 State 的地方被移出了 React views，統一存放在 Store。

接著透過 dispatcher 調用 callback 與 Store 互動形成單向的資料流。

## Redux 的資料流

下面用幫 todo-list 新增 todo 的例子來模擬 Redux 的資料流

### **使用者與 UI 互動**

使用者輸入 `Clean House` 以後送出 todo，此時會觸發幫綁在送出鈕上的 EventListerner。

![img](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/Vk2kDcL.png)

### **EventLister 調用 dispatch**

當 EventListner 被觸發以後會調用 store 的 dispatch 方法，通過 dispatch 方法，一個 action 便被送了出來。

![img](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/KnkrcoZ.png)

### **action 與 state 一起被送進 Root Reducer**

由 dispatch 送出的 action 會交給 rootReducer，rootReducer 裡頭有許多小的 Reducer 分別處理不同的 actions。

action 會被交給有定義這個 action 處理方式的 reducer，除此之外，這個 reducer 還需要知道目前的 state，假設是 `['Cook']` 好了。

![img](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/DZxOnKt.png)

### **產生新的 state**

最後 reducer 會產生新的 state，也就是 `['Cook','Clean House']`，接著重新渲染畫面讓使用者知道已經順利新增 todo。

![img](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/ptC4ZCp.png)

---------------------------

# 為什麼我們需要 Redux？

要回答這個問題，我想也許可以先看結果，也就是甚麼樣的專案適合用到 redux。

1. 專案中有大量的狀態需要管理，而且這些狀態都被許多元件共同使用。
2. 狀態更新的很頻繁
3. 更改狀態的邏輯很複雜時
4. 專案的源碼達到一定規模, 而且多人協作

## **Redux 的特性**

知道了甚麼樣的專案適合使用 Redux 以後，可以回頭來看為甚麼 Redux 可以滿足這些需求。

> A Predictable State Container for JS Apps
 
這是官網給 Redux 下的定義。 為甚麼說 Redux 是一個 `Predictable` State Container 呢? 這個問題可以從 [Three Principles](https://redux.js.org/understanding/thinking-in-redux/three-principles) 入手。

### **Single source of truth**

Global state 都被保存在 Single-state tree 中。

```js
// 透過 store 的 getState 方法來拿到 global state
store.getState()
```

### **State is read-only**

State 只能讀取，除非呼叫透過定義好的 action 發起更新請求。

```js
store.dispatch({
  type: 'ADD_TODO',
  payload: {
      id: 1,
      content: 'Clean House',
  }
})
```

### **Changes are made with pure functions**

這些 action 要如何改變 State 統一在 reducer 裡定義。

```js
function todos(state = initialState, {type, payload}) {
  switch (type) {
    case ADD_TODO:
      return [
        ...state,
        {
          id: id++,
          content: payload.content,
          isDone: false
        }
      ]

    case DELETE_TODO:
      return state.filter(todo =>
        todo.id !== payload.id
      )

    case EDIT_TODO:
      return state.map(todo =>
        todo.id === payload.id ?
          { ...todo, content: payload.content } :
          todo
      )

    default:
      return state
  }
}
```

reducer 被設計成可以組合的，因此可以合併成上面提到的 Single Global state，方便隨時彈性的擴充。

```js
import { combineReducers } from 'redux'
import todos from './todos'
import visibilityFilter from './visibilityFilter'

const rootReducer = combineReducers({
  todos,
  visibilityFilter
})
```

## **結論**

我們可以稍微歸納 Redux 的幾個特性:

1. pure function
2. composition
3. predictable state

我們不難發現當 app 的狀態變得複雜或是多人協作的時候為甚麼 Redux 會是一個好選擇，因為通過 Redux，我們可以

* 清楚的定義每個動作對狀態的改變
* 輕易的擴張狀態的複雜度
* 更高效率的追蹤 app 在不同時間的狀態











