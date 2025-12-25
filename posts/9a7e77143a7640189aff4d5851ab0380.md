---
title: 淺談 React 中的 State 與 Props
---

在 React 中 state 與 props 雖然都被定義在 component 中，但是它們的用途卻大相逕庭，下面列舉幾個它們不同的地方。 

### 以位置定義 props 與 state

在一個元件中 props 代表在元件函式中傳入的參數；而 state 則是在元件內自行管理的，可以想像成在函式內定義的變數。

所以 state 如果被當作參數傳給子元件時，它就變成了子元件的 props。

### 可不可以修改

props 是不可修改的，如果要修改 props 必須在父元素修改好再重新傳入到子元素。 下面是範例：

```jsx
/* Parent.js */
function Parent() {
  const [moneyForSister, setMoneyForSister] = useState(40)
  const allocteMoney = () => {
    setMoneyForSister(70)
  }
  return (
    <div>
      <Sister money={moneyForSister} argue={allocateMoney}/>
    </div>
  )
}

export default Parent;
```
```jsx
/* Sister.js */
function Sister({ money, argue }) {
  <div>我是女兒，我拿到{money}<button onClick={argue}>要求提升到70塊</button></div>
}
export default Sister;
```

![img](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/yzvttHY.png)

當按下 argue 鍵的時候，moneyForSister 會被改為 70，並觸發 Parent 重新渲染，所以 Sister 也會顯示 70 元。

state 則是可以修改的，不過要注意的是 setState 是非同步進行的。

### state 在渲染後才會更新

```jsx
const [count, setCount] = useState(0)

function increment() {
  setCount(count + 1);
}

function handleIncrementThreeTimes() {
  increment()
  increment()
  increment()
}
```
```jsx
const [count, setCount] = useState(0)

function increment() {
  setCount((preState) => {
    preState ++
    return preState
  });
}

function handleIncrementThreeTimes() {
  increment()
  increment()
  increment()
}
```

在第一個範例裡，當 re-render 完成後顯示的是 1，這是因為呼叫 setState 是非同步的，精確一點的來說，使用 setState 做更新時，實際上更新 state 的值是非同步的。所以在第一個範例裡，每次都更新為 count + 1，其實就是 setCount(1) 做了三次而已。

幸好如果要基於目前 state 的值來更新 state，可以使用在 setState 傳入函數的方式，這邊要釐清的一點是 setState 就算是放入函式一樣是非同步的，只不過如果是傳入函式， **react 會將 state 的值拷貝一次並當做參數來記錄當前 state 的變化**。最後再實際上非同步更新 state 的值，所以最後 re-render 完成後顯示的是 3。 

```jsx
const [count, setCount] = useState(0)

function increment() {
  setCount((preState) => {
    preState ++
    console.log(count)
    return preState
  });
}

function handleIncrementThreeTimes() {
  increment()
  increment()
  increment()
}
```

所以在上面這個範例裡，就算想在 setCount 傳入的函式裡獲取 state 的值，一樣不會立即更新。會在 console 得到
```
count: 0
count: 0
count: 0
```

### 為甚麼 setState 是非同步的

想像 Parent 和 Child 在一個 click 事件中同時呼叫 setState 的例子。如果立即更新畫面要渲染多次，但是如果是刻意等到所有的 component 都在它自己的 event handler 裡呼叫 setState，就可以節省很多效能。