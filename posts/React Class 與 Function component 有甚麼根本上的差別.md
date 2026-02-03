---
title: React Class 與 Function component 有甚麼根本上的差別?
---

## class component 與 function component 的差別是什麼？

在 React 的生態系裡，打造 component 有 class 還有 function 的選擇，如果要說他們間有甚麼最大的不同，那肯定是 

> Function component 會捕獲 render 當下的狀態

這個意義可以在後面的解釋裡慢慢被闡述明白。

-----------

### 點餐系統

假設有一家拉麵店的[點餐系統](https://codesandbox.io/s/practical-saha-6bmlb)，使用方式是先選擇下拉選單的品項，然後再按下面的 Order 按鈕確認訂餐。

你應該會發現，不論是按標註 class 或是 function 的按鈕，都會大概在三秒後 alert 訂餐的訊息。

不過如果現在試試看這個順序:

1. 選擇一樣餐點
2. 按下 Order 鈕
3. 切換到另一個餐點

兩種 Order 鈕都試試看，看看有甚麼不一樣。

* 按 Function 按鈕點餐的結果:

![img](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/ef1ea9df61db4095.gif)

* 按 Class 按鈕點餐的結果:

![img](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/019be51e574e7e95.gif)

令人驚訝的是 Class 按鈕的 alert 結果竟然會隨著切換選擇而切換。 哪一個按鈕的反應比較合乎消費者的認知呢? 

答案應該是 Function 按鈕的結果，因為按下點餐按鈕時選的餐點才是真正想要購買的餐點。

--------

### 發生了甚麼事

如果仔細看一下，Class component 的按鈕顯示 alert 的地方可以一窺一二。

```js
class OrderButtonClass extends React.Component {
  showMessage = () => {
    alert('Your order: ' + this.props.food);
  };
```

在 react 裡，props 是 imutable 的，就像是 javascript 的 primitive type 的特性一樣。看看下面的例子。

```js
const a = 3
b = a
a = 4
console.log(b) //3
```

不過上面這個 Class component 的 props 怎麼會一起改變了呢? **事實上，this 是一個 mutable 的東西**，所以 props 被設計成綁在 this 底下就會有隨著原始值一起改變的效果。 

在點餐的例子裡，showMessage 在三秒後才讀取 this.props，可是這個時候 this.props 已經被改動了。

-----------

### 如何解決

1. **提早將 this.props 的值給拷貝出來**

```jsx
class OrderButtonClass extends React.Component {
  showMessage = (food) => {
    alert('Your order: ' + this.props.food);
  };

  handleClick = () => {
    const {food} = this.props;
    setTimeout(() => this.showMessage(food), 3000);
  };

  render() {
    return <button onClick={this.handleClick}>Follow</button>;
  }
}
```

因為 String 原本就是 immutable，所以 `const {food} = this.props` 可以成功達成效果。

現在如果試著這樣拷貝呢? `const item = this.props`

```jsx
class OrderButtonClass extends React.Component {
  showMessage = (item) => {
    alert('Your order: ' + item.food);
  };

  handleClick = () => {
    const item = this.props;
    setTimeout(() => this.showMessage(item), 3000);
  };

  render() {
    return <button onClick={this.handleClick}>Order</button>;
  }
}
```

事實上也是可行的。

2. **閉包**

第二個方法跟第一個方法有點類似，看以下的範例:

```jsx
class OrderButtonClass extends React.Component {
  render() {
    const props = this.props;

    const showMessage = () => {
      alert('Your order: ' + props.food);
    };

    const handleClick = () => {
      setTimeout(showMessage, 3000);
    };

    return <button onClick={handleClick}>Order</button>;
  }
}
```

記得在第一個方法裡我們實驗出 this.props 是 immutable 的，所以把所有的功能函式寫進 render 裡，並且在裡面將 this.props 做一個 snapshot，如此一來功能函式裡都會優先讀取這個 snapshot 的值。

既然所有含式都被寫進了 reder function 裡，便可以不用用到 class 了，改寫成以下的樣子：

```jsx
function OrderButtonClass(props) {
  const showMessage = () => {
    alert('Your order: ' + props.user);
  };

  const handleClick = () => {
    setTimeout(showMessage, 3000);
  };

  return (
    <button onClick={handleClick}>Order</button>
  );
}
```

這樣的寫法其實就是 function component 的寫法，以 argument 的方式傳進 props 一樣可以有 snapshot 的效果，這個效果在最一開始使用 function component 的按鈕點餐的時候便可以發現。

-----------------------

## 補充

如果再回到一開始說的

> Function component 會捕獲 render 當下的狀態

我們可以發現這個狀態不單單指 props，事實上在 function component 中，這個狀態也包含 state。

這次一樣來體驗看看使用 class component 與 function component 建立的點餐系統。

[Function component Demo](https://codesandbox.io/s/function-component-state-demo-tv6qo)

用 Function component 的平台點餐會記住送出時的餐點

![img](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/e266b0e67462b795.gif)

[Class component Demo](https://codesandbox.io/s/class-component-state-demo-kqlhj)

用 Class component 的平台點餐不會記住送出時的餐點

![img](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/04462cb49dbdb6bc.gif)

-------------------------

## 如果在 Function component 也想要獲取最新狀態怎麼辦?

想要在 Function component 擁有像 Class component 的 this.state 一樣的東西可以使用 `useRef` 的 hook，useRef 的值是 mutable 的，並且當 rerender 的時候不會被刷新。

改寫點餐系統成這個樣子:

```jsx
import React, { useState, useRef } from "react";
import ReactDOM from "react-dom";

function OrderSystem() {
  const [content, setContent] = useState("");

  const showContent = () => {
    alert("Your order: " + lastestOrder.current);
  };
  const lastestOrder = useRef('');

  const handleSendClick = () => {
    setTimeout(showContent, 3000);
  };

  const handleContentChange = (e) => {
    setContent(e.target.value);
    lastestOrder.current = e.target.value
  };

  return (
    <>
      <h2>點餐系統(Function)</h2>
      <input
        value={content}
        onChange={handleContentChange}
        placeholder="請輸入您要點的餐點"
      />
      <button onClick={handleSendClick}>Send</button>
    </>
  );
}
```

如此一來，alert 的值就會讀取到最即時在 input 裡的值了。











