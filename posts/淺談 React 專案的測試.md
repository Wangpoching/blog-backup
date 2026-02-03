---
title: 淺談 React 專案的測試
---

## 前言

這篇文章會由小到大的架構去寫。
* 單一 Component 的 Unit test
* 對多個 Compoents 的 Integration test
* 模擬整個瀏覽器的 End-to-end test

不過因為自己才剛接觸測試，所以是以筆記的性質去寫這篇文章，廢話不多說，下面就從前置準備開始吧!

## 前置準備

在 CRA 創建的 React 專案當中，已經裝好了測試用的套件 jest，從 package.json 中可以看到 

```cmd
npm run test
```

可以很方便的進行測試。

不過在使用這個指令之前，請重新安裝 0.6.5 版本的 jest-watch-typeahead，詳細原因參考[這裡](https://stackoverflow.com/questions/70204039/failed-to-initialize-watch-plugin-node-modules-jest-watch-typeahead-filename-js)。

在 cmd 輸入

```cmd
npm install --exact jest-watch-typeahead@0.6.5
```

## 從 function 開始

這是我們要測試的函式:

```js
export const strictFloor = (num) => {
  if (num%1 === 0) {
    return num - 1
  }
  return Math.floor(num)
}
```

這個函式以圖形表示是這樣的:

![img](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/Y5C7JWe.png)

那麼我們會寫幾個 case 來看函式的預期與輸出是不是一樣。

```js
// strictFloor.test.js
import { strictFloor } from './utils'

test('test strictFloor function', () => {
  expect(strictFloor(3)).toBe(2)
  expect(strictFloor(3.5)).toBe(3)
})
```

當我們在 cmd 輸入

```cmd
npm run test
```
會自動尋找有 .test 字串的檔案來跑測試。

### 如果函式有互相依存的關係怎麼辦

我們延續上面的範例稍微修改一下，假設現在 strictFloor 這個函式是這樣子的:

```js
const getPi = () => 3
export const strictFloorV2 = (num) => {
  if (num%1 === 0) {
    return num - 1 + exports.getPi()
  }
  return Math.floor(num) + exports.getPi()
}
```

所以我們在測試的測試檔會改成像這樣子:

```js
// strictFloorV2.test.js
import { strictFloorV2 } from './utils'

test('test strictFloorV2 function', () => {
  expect(strictFloor(3)).toBe(5)
  expect(strictFloor(3.5)).toBe(6)
})
```

測試會通過，不過這個測試是為了 strictFloor 而寫的，如果現在 getPi 變成回傳 3.14，那麼　strictFloor 的測試沒通過就很不直觀，因為應該把錯賴在 getPi 身上。

如果我們可以在測試檔裡面模擬 getPi 的話一切就好多了，先看程式碼:

```js
import * as module from './utils'

test('test strictFloorV2 function', () => {
  jest.spyOn(module, 'getPi').mockReturnValue(5)
  expect(module.strictFloorV2(3)).toBe(7)
  expect(module.strictFloorV2(3.5)).toBe(8)
})
```

我們使用 jest.spyOn 來模擬 module 中的 getPi，不過眼尖的朋友應該會注意到 spyOn 在引用 getPi 的時候是引用 exports.getPi，原因是因為如果直接引用 getPi 我們會無法模擬，詳細可以參考[這篇](https://medium.com/welldone-software/jest-how-to-mock-a-function-call-inside-a-module-21c05c57a39f)。

另一個方法是把 getPi 以及 strictFloor 分成兩個檔案撰寫。

## React Component 的單元測試

測試完單一 function 以後，接著試試看 React Component 的 Unit test，我們想測試的是一個側拉的藍色 Menu，像下面的 gif 這樣:

![img](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/iRoH8Cd.gif)

我們會簡單測試幾個點。
* 沒登入狀態應該有 text 是 Login 的元素
* 點擊 articles 時，網址應該包含 /articles (SPA 的換頁)

```jsx
// Menu.test.js
import Menu from './Menu'
import { BrowserRouter as Router } from 'react-router-dom'
import { screen, render } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import '@testing-library/jest-dom/extend-expect'

describe('Menu Component Login', () => {
  test('Menu should have Login text if logout', () => {
    render(
        <Router>
          <Menu showMenu={true} setShowMenu={jest.fn()}/>
        </Router>)
    expect(screen.getByText('Login')).toBeInTheDocument()
  })
  test('Menu click articles should push history /articles', () => {
    render(
        <Router>
          <Menu showMenu={true} setShowMenu={jest.fn()}/>
        </Router>)
    userEvent.click(screen.getByText('Login'))
    expect(window.location.pathname).toBe('/articles')
  })
})
```

首先將要測試的 Component 引入，接著可以使用 `Render` 來模擬 mount 的動作。

可以將 props 的 function 以 jest.fn() 來代替，如此一來，當函式的內容改變的時候，只要不影響我們要測試的項目，就一樣會通過測試。

這一點滿重要的，謹記 [Kent.C 大師](https://kentcdodds.com/blog/write-tests)的心法 - **盡量不要讓測試去貼近實作**，如此一來才不用頻繁的更改測試。

## 測試整個 Page (Integration Test)

除了一些很特別的元件需要個別做 Unit test 以外，通常我們在意的是很多個元件的相互關係。就以下面這張圖的 ArticlesPage 來說，它包含了 Header、Menu、Paginator、許多 Article 以及 Footer。

![img](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/nX0FEvX.png)

接下來會很有趣，因為這個頁面會發起 fetch 並拿到文章回來。

fetch 的結果與畫面的關係如下:

1. fetch 成功且有文章 => 頁面中應該有 text 是`作者名字`的元素
2. fetch 成功但是沒有文章 => 頁面中應該有 text 是`還沒有任何文章。`的元素
3. fetch 失敗 => 應該導到 HomePage

在測試前端的時候，我們不希望真的去 call API，所以如何模擬發送 API 就是在測試裡面的重要的小事之一了。

### 模仿 fetch

先上程式碼:

```jsx
import themes from '../../themes'
import { ThemeProvider } from '@emotion/react'
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom'
import { screen, render, waitFor } from '@testing-library/react'
import ArticlesPage from './ArticlesPage'
import '@testing-library/jest-dom/extend-expect'
import fetchMock from 'jest-fetch-mock'
fetchMock.enableMocks()

describe('ArticlesPage test', () => {
  beforeEach(() => {
    fetch.resetMocks()
  })
  test('ArticlesPage should redirect to home if fail', async () => {
    fetch.mockReject(() => Promise.reject('API is down'))
    render(
      <ThemeProvider theme={themes.light}>
        <Router>
          <ArticlesPage />
        </Router>
      </ThemeProvider>)
    await waitFor(() => {
      expect(window.location.pathname).toBe('/home')
    })
  })
  test('ArticlesPage should contain authorname if has article', async () => {
    fetch.mockResponseOnce(JSON.stringify({
      success: true,
      data: []
    }), { status: 200, headers: { 'article-amount': 0 } })
    render(
      <ThemeProvider theme={themes.light}>
        <Router>
          <ArticlesPage />
        </Router>
      </ThemeProvider>)
    await waitFor(() => {
      expect(screen.getByText('還沒有任何文章。')).toBeInTheDocument()
    })
  })
  test('ArticlesPage should show no article if no article', async () => {
    fetch.mockResponseOnce(JSON.stringify({
      success: true,
      data: [{
        id: 42,
        name: '王博群',
        authorUid: '1LeBcIh5GbYdzrKiUwq4YwtY0UJ2',
        title: '史詩翻盤！Nadal讓二追三　奪破紀錄第21座大滿貫',
        content: '',
        plainContent: '2022年澳洲網球公開賽',
        createdAt: '2022-01-30T16:12:36.000Z'
      }]
    }), { status: 200, headers: { 'article-amount': 10 } })
    render(
      <ThemeProvider theme={themes.light}>
        <Router>
          <ArticlesPage />
        </Router>
      </ThemeProvider>)
    await waitFor(() => {
      expect(screen.getByText('王博群')).toBeInTheDocument()
    })
  })
})
```

我們可以像一開始模仿 getPi 一樣，試著把 fetch 給代換掉，讓 fetch 回傳我們像要的結果，這件事可以很簡單的經由 `jest-fetch-mock` 這個套件完成。

[這篇文章](https://www.leighhalliday.com/mock-fetch-jest) 裡面有 `jest-fetch-mock` 的詳細說明。

再來要注意 WaitFor 的語法，雖然我們已經不會實際發送 API，但仍然回傳 Promise，所以我們需要將等到 Promise 回來才看看有沒有通過測試。

最後可以注意:

```js
beforeEach(() => {
    fetch.resetMocks()
})
```

我們可以設定 hooks， 讓跑每個測試前先重設一次假的 fetch。

### 模仿 server (MSW)

除了模仿 fetch 還有更極端的手段嗎? 有的，如果可以把 request 攔截下來，讓假的 server 監聽，那不管是 fetch 還是 XMLHttpRequest，都會有效！

上程式碼:

```jsx
import themes from '../../themes'
import { ThemeProvider } from '@emotion/react'
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom'
import { screen, render, waitFor } from '@testing-library/react'
import ArticlesPage from './ArticlesPage'
import userEvent from '@testing-library/user-event'
import '@testing-library/jest-dom/extend-expect'
import { rest } from 'msw'
import { setupServer } from 'msw/node'
import { BASE_URL } from '../../WebAPI'
const server = setupServer()

describe('ArticlesPage test', () => {
  beforeAll(() => server.listen())
  afterEach(() => server.resetHandlers())
  afterAll(() => server.close())
  test('ArticlesPage should redirect to home if fail', async () => {
    server.use(
      rest.get(`${BASE_URL}/articles`, (req, res, ctx) => {
        return res(ctx.status(400))
      })
    )
    render(
      <ThemeProvider theme={themes.light}>
        <Router>
          <ArticlesPage />
        </Router>
      </ThemeProvider>)
    await waitFor(() => {
      expect(window.location.pathname).toBe('/home')
    })
  })
  test('ArticlesPage should show no article if no article', async () => {
    server.use(
      rest.get(`${BASE_URL}/articles`, (req, res, ctx) => {
        return res(
          ctx.set({
            'article-amount': 0,
          }),
          ctx.json({
            success: true,
            data: []          
          })
        )
      })
    )
    render(
      <ThemeProvider theme={themes.light}>
        <Router>
          <ArticlesPage />
        </Router>
      </ThemeProvider>)
    await waitFor(() => {
      expect(screen.getByText('還沒有任何文章。')).toBeInTheDocument()
    })
  })
  test('ArticlesPage should show no article if no article', async () => {
    server.use(
      rest.get(`${BASE_URL}/articles`, (req, res, ctx) => {
        return res(
          ctx.set({
            'article-amount': 10,
          }),
          ctx.json({
            success: true,
            data: [{
              id: 42,
              name: '王博群',
              authorUid: '1LeBcIh5GbYdzrKiUwq4YwtY0UJ2',
              title: '史詩翻盤！Nadal讓二追三　奪破紀錄第21座大滿貫',
              content: '',
              plainContent: '2022年澳洲網球公開賽',
              createdAt: '2022-01-30T16:12:36.000Z'
            }]
          })
        )
      })
    )
    render(
      <ThemeProvider theme={themes.light}>
        <Router>
          <ArticlesPage />
        </Router>
      </ThemeProvider>)
    await waitFor(() => {
      expect(screen.getByText('王博群')).toBeInTheDocument()
    })
  })
})
```

我們可以使用 [MSW](https://mswjs.io/) 來做假的 Server，詳細用法再參考官方網站會更清楚。

## End to End 測試 (Cypress)

最後要直接模擬使用者的體驗了! 使用 [Cypress](https://www.cypress.io/) 可以開啟瀏覽器來實際測試。超級 Fancy 阿!

### 前置準備

1. 安裝 cypress
2. 在 package.json 新增快捷指令 `"cypress:open": "cypress open"`
3. 去 node_modules\cypress\lib\tasks\verify.js, 把 VERIFY_TEST_RUNNER_TIMEOUT_MS 改成 100000，不然很容易不小心 timeout
4. 在 cmd 輸入:
```cmd
npm run start
``` 
在本地開啟 react app
4. 在 cmd 輸入:
```cmd
npm run cypress:open
```
把 cypress 跑起來

### 實際使用 Cypress

如果是第一次在專案使用 Cypress，會自動新增一個 cypress 的資料夾，裡面有一大堆測試，可以刪掉自己寫，記得 cypress 的測試檔要有 `.spec` 的字樣，例如: `auth.spec.js`。

下面上程式碼:

```js
describe("Auth", () => {
  it("test no article", () => {
    cy.visit("http://localhost:3000/react-blog/home")
    cy.intercept('GET', /\/articles\?page=[0-9]&limit=[0-9]$/, {
      statusCode: 200,
      body: JSON.stringify({
        success: "true",
        data: [],
      }),
      headers: {
        'article-amount': '0'
      }
    })
    cy.contains('所有文章').click()
    cy.url().should('includes', 'http://localhost:3000/react-blog/articles')
    cy.contains('還沒有任何文章')
  })
  it("test has article", () => {
    cy.visit("http://localhost:3000/react-blog/home")
    cy.intercept('GET', 'https://react-blog.bocyun.tw/v1' + '/articles?page=1&limit=5', {
      statusCode: 200,
      body: JSON.stringify({
        success: true,
        data: [{
          id: 42,
          name: '王博群',
          authorUid: '1LeBcIh5GbYdzrKiUwq4YwtY0UJ2',
          title: '史詩翻盤！Nadal讓二追三　奪破紀錄第21座大滿貫',
          content: '',
          plainContent: '2022年澳洲網球公開賽',
          createdAt: '2022-01-30T16:12:36.000Z'
        }]
      }),
      headers: {
        'article-amount': '10'
      }
    })
    cy.contains('所有文章').click()
    cy.url().should('includes', 'http://localhost:3000/react-blog/articles')
    cy.contains('王博群')
  })
  it("test error", () => {
    cy.visit("http://localhost:3000/react-blog/home")
    cy.intercept('GET', 'https://react-blog.bocyun.tw/v1' + '/articles?page=1&limit=5', {
      statusCode: 400
    })
    cy.contains('所有文章').click()
    cy.url().should('includes', 'http://localhost:3000/react-blog/articles')
    cy.url().should('includes', 'http://localhost:3000/react-blog/home')
  })
})
```

我們可以看到 cypress 的語法也很簡單，透過 visit(url) 來訪問想要的頁面。

另外，cypress 也提供了類似 MSW 的功能，我們一樣可以設置假的 Server。

### 展示 Cypress

最後要展示上面寫的 Cypress 測試實際跑起來如何，真的會開一個瀏覽器出來，超 OP!

![img](https://raw.githubusercontent.com/Wangpoching/blog-backup/main/assets/images/Gmxb3j6.gif)

最後有人可能會發現在 cypress 沒有使用到類似 `waitfor` 的語法 原因是因為 cypress 會自動等一段時間看看測試是否通過，當然這個時間是可以調整的。

## 結語

這篇文章主要涵蓋到由小到大的範疇:
1. Fnction 測試
2. React Component 單元測試
3. 整合測試
4. End to End 測試

其中重要的觀念有:
1. 如何處理有相依其他函式的函式
2. 如果模擬函式
3. 如何模擬 fetch
4. 如果做假 server

如果這些都忘記了也無妨，個人覺得最重要的還是如何想辦法**把實作的細節跟測試分開，但是又可以測試想要的功能**。



