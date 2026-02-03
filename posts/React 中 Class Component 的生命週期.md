---
title: React 中 Class Component 的生命週期
---

## **從圖表觀察 Class Component 的生命週期**

想要了解 Class Component 的生命週期，可以在 React 的官網上找到[react-lifecycle-methods-diagram](https://projects.wojtekmaj.pl/react-lifecycle-methods-diagram/)

![img](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/6MRnMbT.jpg)

從這張圖可以很好的展示了在 Mount, Updating 還有 Unmounting 的過程中會呼叫哪一些函式。

**Mount** 顧名思義是要將 Component 給掛到 DOM 上面，所以說如果 DOM 裡面如果不存在這個 component，肯定會執行 Mount 的流程。

**Updating** 是指將 Component 進行更新，例如原本 DOM 上面已經存在某個 component，如果 setState 被觸發了，那麼會走 Updating 的流程。

**Unmount** 是指從 DOM 上面拿掉 component，所以說在 component 被 unmount 之後，如果想要再讓它出現，必須走 Mount 的流程。

下面來一一看看圖裡面的函式的實際應用吧!

## **Constructor**

Constructor 會在 component 進入 Mount 的流程的最一開始被呼叫，在這裡最常做的事情是設定 component 的 state，另外要跑一次 `super()`，跑一次 Compoent class 的 constructor。

```jsx
constructor(props) {
  super(props);
  this.state = {
    number: 1
  };
  console.log("construct Component");
}
```

## **shouldComponentUpdate**

從生命週期的圖中可以看到 shouldComponentUpdate 會在 update 的流程中呼叫 render 前使用，如果回傳 false 則不會更新，如果回傳 true 則會接續更新的流程，通常可以用在優化效能方面，看下面的例子。

```jsx
import { Component } from "react";
import Content from "./Content";

class Title extends Component {
  constructor(props) {
    super(props);
    this.state = {
      content: "老鼠"
    };
    console.log("construct Title");
    this.handleChangeContent = this.handleChangeContent.bind(this);
  }
  shouldComponentUpdate(nextProps, nextState) {
    if (nextState.content !== this.state.content) return true;
    return false;
  }
  handleChangeContent() {
    console.log("clicked");
    const options = ["倉鼠", "銀狐", "老公公鼠"];
    this.setState({
      content: options[Math.floor(Math.random() * options.length)]
    });
  }
  render() {
    console.log("render Title");
    return (
      <div>
        <h1>Title: 老鼠家族</h1>
        {<Content content={this.state.content} />}
        <button onClick={this.handleChangeContent}>改變內文</button>
      </div>
    );
  }
}

export default Title;
```

我們可以透過檢查 state.content 有沒有改變，來決定是不是要更新 component，這有賴於 shouldComponentUpdate 的參數裡會帶入即將改變的 props 以及 state。

來看一下 Demo 的影片，可以發現只有在 content 的內容實際變動的時候，才會觸發 render function。

![img](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/FaQJ8vv.gif)

## **componentDidMount && componentWillUnmount**

componentDidMount 會在 component 被掛載到 DOM 上時被呼叫，而 componentWillUnmount 則會在 component 被 unmount 前呼叫。

他們常常會被成雙使用，因為可能在 component 掛載後的 sideEffect 需要在 unmount 時被清除。

看看下面的範例:

```jsx
//Title.js
import { Component } from "react";
import Content from "./Content";

class Title extends Component {
  constructor(props) {
    super(props);
    this.state = {
      content: "老鼠",
      isShow: true
    };
    this.handleChangeContent = this.handleClick.bind(this);
  }
  handleClick() {
    const options = ["倉鼠", "銀狐", "老公公鼠"];
    this.setState({
      content: options[Math.floor(Math.random() * options.length)],
      isShow: !this.state.isShow
    });
  }
  render() {
    return (
      <div>
        <h1>Title: 老鼠家族</h1>
        {this.state.isShow && <Content content={this.state.content} />}
        <button onClick={this.handleChangeContent}>開關</button>
      </div>
    );
  }
}

export default Title;
```

```jsx
//Content.js
import { Component } from "react";

class Content extends Component {
  constructor(props) {
    super(props);
  }
  componentDidMount() {
    console.log("did mount");
    this.timer = setTimeout(() => {
      alert(this.props.content);
    }, 2000);
  }
  componentWillUnmount() {
    console.log("Will Unmount");
    clearTimeout(this.timer);
  }
  render() {
    return (
      <div>
        <h1>Content: {this.props.content}</h1>
      </div>
    );
  }
}

export default Content;
```

點擊按鈕除了可以調控是要將 Content component 給放上 DOM 或者是從 DOM 上面移除，也會同時修改 state.content 的內容。

在 DidMount 兩秒後會 alert 提醒新改變的 state.content 的值，不過因為如果 Content component 被 unmount 的情況下，實際上就不需要 alert 了，這時候在 componentWillUnmount 將 timer 刪掉便是很好的做法。

我們來看，點擊一次讓內容以及 alert 出現的情況。

![img](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/jFhSsY7.gif)

再接著看，連續點擊兩次讓內容快速出現又消失，這一次不會跳出 alert。

![Imgur](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/9OUs89H.gif)

### **componentDidUpdate**

componentDidUpdate 比較類似於 componentDidMount，不過他是在每一次元件更新時，被確保會被執行一次，除非 shouldComponentUpdate 回傳 false。

像 componentDidMount 一樣，可以拿來比對 prevProps/prevState 及 this.props/this.state 的 狀態差異，做像是存取 DOM、 重畫 Canvas、 AJAX 等等。
