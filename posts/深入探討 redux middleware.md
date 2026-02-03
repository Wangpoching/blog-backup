---
title: 深入探討 redux middleware
---

## 前言

Redux 提供了 middleware 的功能，讓我們可以在 action 被真正送到 reducer 以前，可以做許多客製化的事情。

最重要當然是處理非同步的事件，像是可以發 API 請求資料。其他像是用 redux-logger 幫助記錄存入 redux 前後的狀態也是常用的 middleware 之一。

以我的了解來說，middleware 可以說是 pre-reducer 的 hooks。

如果還不是很明白 middleware 被使用的時機，可以看看下面這張圖：

![img](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/j3yIbiz.png)

## 如何使用 middleware

```js
import { applymiddleware, createStore } from 'redux'
import logger from 'redux-logger'

const store = createStore(reducer, applyMiddleware(logger))
```

在創建 store 的時候，只要簡單的將要用到的 middleware 當作參數放進 applyMiddleware 裡，就可以成功讓 store 與 middlewares 連結。

在 logger 的例子裡，所有 action 都會先經過 logger，印出進出 reducer 前後的狀態。

## redux-logger

官方提供的 logger 函式的範例是這樣子的:

```js
const logger = store => next => action => {
  console.log("dispatching1", action);
  let result = next(action);
  console.log("next state1", store.getState());
  return result;
};
```

看起來太簡化了，所以在這裡先改成用 function declaration 的方式寫

```js
function logger(store) {
  return function wrapDispatchToAddLogging(next) {
    return function dispatchAndLog(action) {
      console.log('dispatching', action);
      let result = next(action);
      console.log('next state', store.getState());
      return result;
    }
  }
}
```

至於為甚麼要包這麼多層，只好繼續看下去。

## createStore 與 applyMiddleware

為了瞭解 logger 的寫法必須往前追溯 createStore 以及 applyMiddeware 是如何運作的。

首先先來看 createStore 的部分，store 有分兩種，一種是**有 enhancer 的 store 以及沒有 enhancer 的 store**。為了方便理解，在這邊可以思考成**有 middleware 的 store  以及沒有 middleware 的 store**。

### createStore

createStore 擁有三個參數：

* **reducer**: 就是實際處理 action 的地方
* **preloadedState**: 預設的狀態，會覆蓋 reducer 中預設的狀態。也就是會覆蓋我們會在 reducer 中設定狀態的初始值 reducer(state=INIT_STATE, action) 。
* **enhancer**: 有用過 react-redux 提供的 connect 的話，對於 HOC 應該不陌生。而 enhancer 實際上就是一個 **Higher-Order Function (HOF)**，將 redux store 送進 enhancer 裡，回傳包裝過的 redux store。

這個時候機靈的小夥伴們可能開始疑惑了，如果 applyMiddleware 會回傳一個 enhancer ，為了麼上面的範例裡是把 `applyMiddleware(logger)` 放在第二個參數呢?

這時候可以從節錄的 createStore 源碼得到解答:

```js
export default function createStore(reducer, preloadedState, enhancer) {
  ...
  
  if (typeof preloadedState === "function" && typeof enhancer === "undefined") {
    enhancer = preloadedState;
    preloadedState = undefined;
  }

  if (typeof enhancer !== "undefined") {
    if (typeof enhancer !== "function") {
      throw new Error("Expected the enhancer to be a function.");
    }

    return enhancer(createStore)(reducer, preloadedState);
  }

  ...
}
```

第四行的地方表明了當第二個參數是一個 function 而且第三個參數沒有定義的情況，
會把 preloadedState 的值傳給 enhancer ，並且把 preloadedState 設定成 undefined。

在定義好各自的角色以後，最後，用 enhancer 把 reducer 包裝起來，變成一個有 enhancer 的 reducer。

### applyMiddleware

applyMiddleware 可以產生一個 store enhancer。它的效果是可以用 currying 將多個 middleware 串聯在一起，變成 middleware chain。

畫個圖感覺會像這樣子:

![img](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/5yHAcgI.png)

感覺應該還是滿不清楚的，再繼續看下去回過頭來再看這張圖會更清楚一些。

下面是 applyMiddleware 的源碼：

```js
export default function applyMiddleware(...middlewares) {
  return createStore => (reducer, ...args) => {
    const store = createStore(reducer, ...args);
    let dispatch: Dispatch = () => {
      throw new Error(
        'Dispatching while constructing your middleware is not allowed. ' +
          'Other middleware would not be applied to this dispatch.'
      )
    }
    
    const middlewareAPI = {
      getState: store.getState,
      dispatch: (action, ...args) => dispatch(action, ...args)
    };
    const chain = middlewares.map(middleware => middleware(middlewareAPI));
    dispatch = compose(...chain)(store.dispatch);

    return {
      ...store,
      dispatch
    };
  };
}
```

首先我們回想 createStore 在有 enhancer 的情況下會返回 `enhancer(createStore)(reducer, preloadedState);` 這樣的東西。

這邊的 enhancer 我們用簡單的範例就是 applyMiddleware(logger) 回傳的 function。 接著我們注意到源碼的第二行要帶入的參數就是 createStore，最後再把返回的函式帶入 reducer。

最後返回的東西會跟原始的 createStore 有點像，一樣有 subscribe 以及 getState。 不過看起來 dispatch 似乎被修改過了，也就是完成了對 createStore 的修飾。

接下來繼續詳細的看 dispatch 是如何被修改。

#### 建立一個新的 redux store (第 3 行)

第三行的地方呼叫了 createStore(reducer, ...args)，這邊的 ...args 是 preloadedState，由於 preloadedState 在前面把函式傳給 enhancer 後，被設定為 undefined，所以可以看成 createStore(reducer)。

接著先跳到 createStore 的源碼下半段，如果沒有 enhancer 會做的事情：

```js
export default function createStore(reducer, preloadedState, enhancer) {
  ...

  let currentReducer = reducer;
  let currentState = preloadedState;

  function getState() {
    return currentState;
  }

  function dispatch(action: A) {
    currentState = currentReducer(currentState, action);
    return action;
  }

  dispatch({ type: ActionTypes.INIT });

  const store = {
    dispatch,
    subscribe,
    getState
  };
  return store;
}
```

裡面做的事情就是定義了 getState, dispatch, subscribe 然後發送一個 INIT 的 action。

#### compose middleware (第 4–16 行)

我們再看一次 logger 函式。

```js
function logger(store) {
  return function wrapDispatchToAddLogging(next) {
    return function dispatchAndLog(action) {
      console.log('dispatching', action);
      let result = next(action);
      console.log('next state', store.getState());
      return result;
    }
  }
}
```

前面提到過 middleware chain，其中 next 會不斷指向下一個 middleware 函式，所以，在 dispatch action 後進入 middleware 的函式， action 不斷被往下一個 middleware 傳遞 (logger 的第 5 行)。

接著回到 applyMiddleware 的第 4–16 行

```js
let dispatch: Dispatch = () => {
  throw new Error(
    'Dispatching while constructing your middleware is not allowed. ' +
      'Other middleware would not be applied to this dispatch.'
  )
}

const middlewareAPI = {
  getState: store.getState,
  dispatch: (action, ...args) => dispatch(action, ...args)
};
const chain = middlewares.map(middleware => middleware(middlewareAPI));
dispatch = compose(...chain)(store.dispatch);
````

首先透過 map 將經過修改的 getState 與 dispatch 傳入到每一個 middleware 中的第一個參數。為了避免 middleware 在建立時，其中一個 middleware 函式呼叫了 store.dispatch 讓程式壞掉。

現在 chain 會長得像這樣:

`[middleware1 = next => action => {...}, middleware2 = next => action => {...}, ...]` 如果不太清楚的話可以回頭看看 logger 的寫法。

現在 chain 裡面儲存了很多的 `next => action => {...}`，下個步驟就是將每個 middleware 的 next 都指向下一個 middleware 函式。

而答案就在 compose 這個函式裡面。 底下是 compose 的實作。

```js
export default function compose(...funcs) {
  if (funcs.length === 0) {
    return (arg) => arg
  }

  if (funcs.length === 1) {
    return funcs[0]
  }

  return funcs.reduce((a, b) => (...args) => a(b(...args)))
}
```
reduce 的用法可以參考 [MDN Web Docs](https://developer.mozilla.org/zh-TW/docs/Web/JavaScript/Reference/Global_Objects/Array/Reduce)。

假設有兩個 middleware 分別是 logger 與 reportError，情況會像下面這樣:

```js
const logger = (next) {
  return function dispatchAndLog(action) {
    console.log('dispatching', action);
    let result = next(action);
    console.log('next state', store.getState());
    return result;
  }
}

const reportError = next => action => {...}

// reduce 回傳的函式
return (next) => logger(reportError(next))
```

所以 reduce 最後會回傳一個函式，**這個函式暴露出最後一個 middleware 的 next 參數**，想當然爾要放入 dispatch 來完成對 dispatch 的包裝。

現在再看一次剛剛的圖應該清楚多了!

![img](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/5yHAcgI.png)

如果把事情簡化成只有一個 middleware，也就是 logger，會更好解釋。此時的 dispatch 也就會是:

```js
dispatch = (action) {
  console.log('dispatching', action);
  let result = store.dispatch(action);
  console.log('next state', store.getState());
  return result;  
}
```

#### 修改 redux store 中的 dispatch 函式 (第 18–22 行)

applyMiddleware 的最後一個步驟就是把原本串聯在一起的 middleware 傳到 redux 中，改掉原本的 dispatch 函式。到此為止加強版的 store 就被建立起來了。

最後當 dispatch 被呼叫時，就會先經過 middleware 的邏輯以後才實際發出 dispatch 讓 reducer 處理。


