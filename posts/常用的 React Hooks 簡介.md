---
title: 常用的 React Hooks 簡介
---

## **useState**

```js
const [state, setState] = useState(initialState);
```

useState 的用法像這樣子，在首次 render 時，state 的值由 initialState 來決定; setState 則是用來修改 state 值的函式。

```js
setState(newState)
```

setState 用來更新 state。它接收一個新的 state 後元件將重新 render。

這邊有兩點要注意：

1.  render 以後 useState 回傳的 state 是更新過後的值。
2. setState 不會在被 render 後改變指向的位置，所以可以放心地不在 dependencies 中放入。

### 函數式更新

setState 並不一定要使用直接代入要更新的值的方式使用。它可以像下面這樣使用。

```
setState(prevState => prevState + 1)
```

透過代入匿名函式的方式，可以拿到上一個 state 來使用，如果 state 的更新是基於上一個 state，可以用這個方法，此外，這個方法也不用將 state 寫進 dependencies 裡。

### 與 class component setState 不同的地方

與 class component 的 setState 方法不同，沒有辦法自動合併更新 object，所以可以搭配 ES6 的 object spread 語法來更新，像下面這樣:

```
setState(prevState => {
  return {...prevState, ...updatedValues}
})
```

### LazyInitializer

initialState 參數只會在初始 render 時使用，在後續 render 時會被忽略。其實 useState 也可以傳入匿名函式，這個函式的回傳值就會是 state 的初始值，而且只會被調用一次。

```
const [state, setState] = useState(() => {
  const initialState = complexComputation(props)
  return initialState
})
```

不過因為這個函式的運算速度會影響第一次 render 的效能，所以如果真的要進行太複雜的計算也可以考慮移到 useEffect。

### state 不更新的情況

如果使用跟目前 state 一樣的值更新 state，React 將不會重新 render。

---------------------------------

## **useEffect**

```js
useEffect(didUpdate)
```

useEffect 接受傳入匿名函式，並且預設會在每一次 render 結束以後執行這個匿名函式，但我們也可以選擇它們在某些值改變的時候才執行。

### 清除一個 effect

很多時候，在 component 離開螢幕之前需要清除 effect 的效果，比如說 subscription 或計時器的 ID。

傳遞到 useEffect 的 function 可以回傳一個清除的 function，這個 function 會在 component 從 UI 被移除前執行。

```js
useEffect(() => {
  const timer = setTimeout(doSomething, 1000)
  return () => {
    // Clean up the timer
    clearTimeout(timer)
  }
})
```

### 有條件的觸發 effect

useEffect 可以傳遞第二個參數，它是該 effect 所依賴的值的 array，當每次重新 render 後，這個 array 會被比較是否一模一樣，如果有改動就會觸發 useEffect 的效果。

```js
// 當 count 改變時才會建立計時器
useEffect(() => {
  const timer = setTimeout(doSomething, 1000)
  return () => {
    // Clean up the timer
    clearTimeout(timer)
  }
}, [count])
```

----------------------------

## **useLayoutEffect**

useLayout 的用法基本上與 useEffect 相同，因為不是所有的 effect 都可以被延後。例如，使用者可見的 DOM 改變最好在下一次繪製之前同步觸發，這樣使用者才不會感覺到視覺不一致，而 useLayoutEffect 可以確保在 render 到螢幕前被執行。

---------------------------

## **useContext**

```js
const value = useContext(MyContext);
```

useContext 接收一個由 React.createContext 所建立的物件，並且會回傳該 context 目前的值。

聽起來有點抽像，再繼續看看它的使用。 

```js
const themes = {
  light: {
    foreground: "#000000",
    background: "#eeeeee"
  },
  dark: {
    foreground: "#ffffff",
    background: "#222222"
  }
};

const ThemeContext = React.createContext();

function App() {
  return (
    <ThemeContext.Provider value={themes.dark}>
      <Button />
    </ThemeContext.Provider>
  );
}

function Button() {
  return (
    <div>
      <ThemedButton style={{ background: theme.background, color: theme.foreground }}/>
    </div>
  );
}
```

Context.Provider 可以將 value 給傳遞到他所有的子元件，而子元件透過 useContext(Context) 可以將 value 取出。

最後有兩點要注意:

1. Context 目前的值是取決於上層 component 距離最近的 <MyContext.Provider> 的 value prop
2. 當 component 上層最近的 <MyContext.Provider> 更新時，會觸發重新 render

----------------------------------

## **useReducer**

useReducer 是 useState 的替代方案，它接收一個 reducer 以及初始值。 並且回傳 現在的 state 以及其配套的 dispatch 方法。

至於甚麼是 reducer 以及 dispatch 下面會解釋。

當我們需要一次管理許多 state，useReducer 會比 useState 更適用，我們可以透過傳遞一個 diapatch 而不用傳遞很多個 callback function。

用法像下面這樣，範例取自 [React Hooks 官方文件](https://zh-hant.reactjs.org/docs/hooks-reference.html)

```jsx
const initialState = {count: 0};

function reducer(state, action) {
  switch (action.type) {
    case 'increment':
      return {count: state.count + 1};
    case 'decrement':
      return {count: state.count - 1};
    default:
      throw new Error();
  }
}

function Counter() {
  const [state, dispatch] = useReducer(reducer, initialState);
  return (
    <>
      Count: {state.count}
      <button onClick={() => dispatch({type: 'decrement'})}>-</button>
      <button onClick={() => dispatch({type: 'increment'})}>+</button>
    </>
  );
}
```

useReducer 的其他特性則和 useState 一樣，包括:

1. dispatch 和 setState 一樣不會隨著 rerender 而改變
2. 支援 LazyInitializer
3. 如果在 Reducer Hook 回傳的值與目前的 state 相同，則不會再次觸發渲染

-------------------------------

## **useCallback**

在一個元件裡面，有一些函式並不需要在每次 render 都被更新，除非是它所依賴的值發生變化，為了讓函式有條件的更新，可以使用 useCallback。

```js
const memoizedCallback = useCallback(
  () => {
    doSomething(a, b)
  },
  [a, b],
)
```

這個例子裡 doSomething 依賴了 a, b，所以在第二個參數上以 array 的方式填上依賴的變數，這樣一來，在每次 render 時，新的跟舊的 array 會被拿來比較是否相同，不同的話會更新這個函式。

--------------------------------

## **useMemo**

useMemo 與 useCallback 大同小異，只不過它會回傳一個值而不是 function。如果有些值需要透過複雜的運算，那麼 useMemo 便可以讓需要重新計算時再重新計算即可。

```js
const memoizedValue = useMemo(() => doComplexCompute(a, b), [a, b])
```

------------------------------

## **useRef**

useRef 是一個十分有趣的 hook，因為與其他 hook 不同，它會回傳給你一個 mutable 的 object，並且每次 render 這個 object 都是一樣的。

所以在讀取 useRef 的 current 屬性時，它並不會被綁定在某次 render，它會隨時更新，會拿到甚麼值端看使用者何時讀取它。

它最常被用到的地方是 uncontrolled component，用法如下:

```jsx
  function InputElement() {
    const refContainer = useRef()
    return (
      <input ref={refContainer} />
    )
  }
```

當我們要取值的時候可以這樣寫:

```
const value = refContainer.current.value
```

此外，如果要記錄 render 的次數等等的功能也很適合使用 useRef

最後要注意的是，useRef 在其內容有變化時並不會通知你。變更 current 屬性不會觸發重新 render。



