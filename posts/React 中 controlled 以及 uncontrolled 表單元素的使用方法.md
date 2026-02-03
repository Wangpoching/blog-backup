---
title: React 中 controlled 以及 uncontrolled 表單元素的使用方法
---

表單元素在 HTML 裡面是一個很有趣的存在，因為它有自己的狀態，這麼說有些抽象，就拿 `input [type=text]` 來說，當使用者在輸入文字時，使用者輸入的資料會綁在 input 元素上，這樣一來當使用者送出表單便可以順利把資料傳送。

雖然表單元素讓瀏覽器控制看起來沒什麼問題，但如果你想要更多呢? 

比如說，
1.你有自己的規則想要檢查使用者的輸入
2.把表單資料送出的時候想要自動在 request 加上一些 header 或者欄位。

# Controlled Components

## 將控制權轉交給 react

其實不只 `input`，諸如 `textarea` 或者是 `select` 等元素也都會有自己的狀態，這個狀態會隨著使用者的動作而更新。

等等，這聽起來跟 react 使用的概念好像喔! 就好像這些元素原本就有 state，當使用者輸入會引發 handler，而 handler 會呼叫 setState，使得在 state 在更新以後這些元素可以即時反映出輸入值一樣。

事實上，把這個概念用 react 實作的表單元素，就叫做 `controlled components`。

## **input**

來個簡單的範例，這個範例是希望可以讓使用者填入名字，然後在送出表單之後 alert 自己的名字。

```jsx
function EnrollForm() {
  const [formContent, setFormContent] = useState({
    username:''
  })
  const handleInputChange = (e) => {
    setFormContent({
      username: e.target.value
    })
  }
  const handleSubmit = (e) => {
    e.preventDefault()
    alert(formContent.username)
  }
  return (
    <form onSubmit={handleSubmit}>
      <label htmlFor="username">暱稱</label>
      <input 
        id="username" 
        type="text" 
        placeholder="您的回答" 
        name="username"
        value={formContent.username}
        onChange={handleInputChange}
      />
      <input type="submit" value="Submit" />
    </form>
  ) 
}
```

這邊有幾點可以注意:

1. 首先創建一個 state 準備儲存表單資訊
2. 將 input 的 value 轉交給 state 處理
3. **handleInputChange 函式**: 
這是監聽 input 的內容變化的函式，當 input 的內容一變化，及時反映到 state 的值，同時觸發渲染，讓使用者看到變化。
4. **handleSubmit 函式**: 
監聽 submit 事件，當 submit 事件發生，先將瀏覽器預設的動作給關閉，然後就得到了對 submit 事件 100% 的掌控權!

2、3 步是其中將控制權轉交給 react 的精髓所在。

雖然這麼做要多打程式碼，但現在我們可以輕易地將 input 裡面的值可以交給其他 component 使用，或是搭配其他 handler 做重置表單內容等等的舉動。

最後眼尖的人會發現 label 元素使用了 htmlFor 而不是 for，這是因為 for 關鍵字在 javascript 已經被占用的緣故。

## **textarea**

使用 controlled textarea 的方法基本上與 input 沒有太大的差異，只有一些小細節，如果把剛剛的範例用 textarea 呈現會像這樣子：

```jsx
function EnrollForm() {
  const [formContent, setFormContent] = useState({
    username:''
  })
  const handleInputChange = (e) => {
    setFormContent({
      username: e.target.value
    })
  }
  const handleSubmit = (e) => {
    e.preventDefault()
    alert(formContent.username)
  }
  return (
    <form onSubmit={handleSubmit}>
      <label htmlFor="username">暱稱</label>
      <textarea
        id="username"
        name="username"
        value={formContent.username}
        onChange={handleInputChange}
      />
      <input type="submit" value="Submit" />
    </textarea>
  ) 
}
```

這邊要注意的是原本 textarea 的值是由他的 child 決定的，像這樣子:

```html
<textarea>
  我是 textarea 裡面的內容
</textarea>
```

但是在 React 的 textarea component 裡面是由 value 的屬性決定。

## **select**

先看一下一般狀況下 select 元素的使用:

```html
<select name="濃湯種類">
  <option value="巧達濃湯">巧達濃湯</option>
  <option value="番茄濃湯">番茄濃湯</option>
  <option selected value="玉米濃湯">玉米濃湯</option>
</select>
```

觀察一下玉米濃湯有 selected 屬性，代表現在選的選項是玉米濃湯，不過在 react 裡使用 select component 會稍微不同：

```jsx
function Selector() {
  const [formContent, setFormContent] = useState({
    purre:'玉米濃湯'
  })
  const handleChange = (e) => {
    setFormContent({
      purre: e.target.value
    })
  }
  const handleSubmit = (e) => {
    e.preventDefault()
    alert('Your order: ', formContent.purre)
  }
  return (
    <form onSubmit={handleSubmit}>
      <label htmlFor="purre">濃湯種類</label>
      <select 
        name="purre"
        id="purre"
        value={formContent.purre}
        onChange={handleChange}
      >
        <option value="巧達濃湯">巧達濃湯</option>
        <option value="番茄濃湯">番茄濃湯</option>
        <option value="玉米濃湯">玉米濃湯</option>
      </select>
    </form>
  )
}
```

注意在這個時候 select 有 value 的屬性，這樣一來可以綁定事件在 selector 上就好，比較簡易。

小結一下，不論是 `input [type=text]`、textarea 或者是 selector，只要採用 react 書寫，都適用 value 這個屬性來管理。

## **批量處理**

另一個小細節是如何處理多個 input 的狀況，如果要幫每個 input 都寫一個 handler 也太麻煩了吧! 這時候可以幫 input 加上 name 的屬性來讓同一個 handler 統一判斷，範例如下:

```jsx
function Selector() {
  const [formContent, setFormContent] = useState({
    username: ''
    purre: '玉米濃湯'
  })
  const handleInputChange = (e) => {
    setFormContent((formContent) => {
      setFormContent({
        ...formContent,
        [e.target.name]: e.target.value
      })
    }
  }
  const handleSubmit = (e) => {
    e.preventDefault()
    alert(`Your name: ${formContent.username}\r\nYour order: ${formContent.purre}`)
  }
  return (
    <form onSubmit={handleSubmit}>
      <label htmlFor="username">暱稱</label>
      <input 
        id="username" 
        type="text" 
        placeholder="您的回答" 
        name="username"
        value={formContent.username}
        onChange={handleInputChange}
      />
      <label htmlFor="purre">濃湯種類</label>
      <select 
        name="purre"
        id="purre"
        value={formContent.purre}
        onChange={handleInputChange}
      >
        <option value="巧達濃湯">巧達濃湯</option>
        <option value="番茄濃湯">番茄濃湯</option>
        <option selected value="玉米濃湯">玉米濃湯</option>
      </select>
      <input type="submit" value="Submit" />
    </form>
  )
}
```

```js
  const handleInputChange = (e) => {
    setFormContent((formContent) => {
      setFormContent({
        ...formContent,
        [e.target.name]: e.target.value
      })
    }
  }
```

這一段使用了 ES6 `computed property name` 的語法，可以輕鬆愉快的修改 state 的狀態。

## **其他小細節**

* `input [type=file]` 在 react 裡是 uncontrolled 的元素喔! 只能讀取無法修改。
* 避免在 value 的地方使用 `undefied` 或者是 `null`，因為會失去對 input 的控制。像下面這個範例，就算沒有定義 onChange 函式，input 還是可以正常輸入...

```
function Example() {
  return (
    <input 
      value={null}
    />
  ) 
}
```

# uncontrolled component

提了這麼多 controlled component 的用法，或許會好其是不是有需要用到 uncontrolled component 的時候。

比如說有些時候我們可能只是想要很簡單的去取得表單中某個欄位的值，或者是有一些情況下需要直接操作 DOM（音樂播放器中有許多方法是直接綁在 `<video>` 元素上的)。

想要在 react 中使用 uncontrolled 的話需要 useRef 的協助。 useRef 有幾個特色:

1. useRef 會回傳一個物件，這個物件不會隨著每一次畫面重新渲染而指向到不同的物件，可以一直指向同一個物件
2. 在回傳的物件中，透過 current 屬性可以取得更動後的值

```jsx
  const refContainer = useRef()
  function InputElement() {
    return (
      <input ref={refContainer} />
    )
  }
```

當我們要取值的時候可以這樣寫:

```
const value = refContainer.current.value
```

為甚麼可以這樣寫呢? 想像我們用 document.querySelector 選到該元素後，保存在 useRef 回傳物件的 current 屬性內，因為 current 的值是 mutable 的，所以當我們想取用的時候都會拿到最新的值。





