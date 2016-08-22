# refnux

> re-fn-ux with emphasis on fn

React's [Stateless Functions][stlss] means we can use simple functions
instead of instances of component classes.

By also letting go of partial updates to the DOM tree, we can make a
super simple state store with actions that are like the flux pattern.

Refnux is like redux, but using only functions instead of reducers.

# initialize.js

```javascript
import ReactDOM from 'react-dom';
import React from 'react';
import App from 'components/App';

import {createStore, Provider} from 'refnux';

var store = createStore({counter:42});

document.addEventListener('DOMContentLoaded', () => {
  ReactDOM.render(<Provider store={store} app={App} />, document.querySelector('#app'));
});
```

## Store

The store is created over a simple state. This state will be
propagated to all `connect`ed view functions and actions.

```javascript
var store = createStore({counter:42});
```

### dispatch on store

The store exposes a dispatch function (see dispatch below)

```javascript
store.dispatch(myaction)
```

### getState on store

The store also exposes a getState to get the current state

```javascript
var current = store.getState()
```

## Provider

The Provider coordinates `connect`, `action` and rerendering of the
DOM tree. The `app` provided must be a function.

```
<Provider store={store} app={App} />
```

# App.js

```javascript
import React from 'react'
import {connect} from 'refnux'

var action = (inc) => ({counter}) => {
    return {counter:counter + inc}
}

export default connect(({counter}, dispatch) => {
    return <div id="content">
        <button onClick={() => dispatch(action(-1))}>-</button>
        <span>{counter}</span>
        <button onClick={() => dispatch(action(1))}>+</button>
    </div>
});
```

## Connect

The `connect` function ensures the view function receives the state
and `dispatch` on every rerender.

```javascript
connect((state, dispatch) => { ... })
```

## Actions

### dispatch runs an action

```javascript
var myaction = (state) => { ... }
...
dispatch(myaction)
```

### an action is just a function

An action is just a function taking the state and returning the keys
that have been changed.

```javascript
var action = (state) => {
    return {counter:state.counter + 1}
}
```

Use scope to pass parameters to actions.

```javascript
var action = (inc) => ({counter}) => {
    return {counter:counter + inc}
}
```

### async

All actions receive a second argument that is a `dispatch` function to
be used asynchronously.

```javascript
var myaction = (state, dispatch) => { ... }
...
dispatch(myaction)
```

#### async example

```javascript
var handleResponse = (user) => (state) => {
    return {user:user, info:"Got user"}
}

var requestUser = (userId) => (state, dispatch) => {
    io.emit('getUser', userId, (user) => {
        dispatch handleResponse(user)
    })
    return {info:"Requesting user"}
}
```

N.B. it is an error to use the dispatch function synchronously.


#### ISC License (ISC)

Copyright (c) 2016, Martin Algesten <martin@algesten.se>

Permission to use, copy, modify, and/or distribute this software for
any purpose with or without fee is hereby granted, provided that the
above copyright notice and this permission notice appear in all
copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL
WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE
AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL
DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR
PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER
TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
PERFORMANCE OF THIS SOFTWARE.


[stlss]: https://facebook.github.io/react/docs/reusable-components.html#stateless-functions
