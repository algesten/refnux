
{createStore, Provider, connect} = require '../src/refnux'

{createFactory} = require 'react'
{renderToString} = require 'react-dom/server'
{div} = require('react').DOM
pf = createFactory Provider

describe 'connect', ->

    store = createStore(panda:42)

    it 'requires a function arg', ->
        assert.throws (->connect null), 'connect requires a function argument'

    it 'connects functions on store render', ->
        app = connect vf = spy -> div(null, 'abc')
        pel = pf({app, store})
        eql vf.args, []
        html = renderToString pel
        eql html, '<div data-reactroot="" data-reactid="1" '+
            'data-react-checksum="-1466167168">abc</div>'
        eql vf.args, [[{panda:42}, store.dispatch, undefined]]

    it 'passes properties to wrapped component', ->
        props = { some: 'prop' }
        component = connect vf = spy -> div(null, 'abc')
        app = -> component(props)
        pel = pf({app, store})
        eql vf.args, []
        html = renderToString pel
        eql vf.args, [[{panda:42}, store.dispatch, props]]

    it 'complains if connected function is used outside provider', ->
        app = connect -> div(null, 'abc')
        assert.throws app, 'No provider in scope. View function outside Provider?'

    it 'tidies up after render', (done) ->
        app = connect -> div(null, 'abc')
        pel = pf({app, store})
        renderToString pel
        setTimeout ->
            assert.throws app, 'No provider in scope. View function outside Provider?'
            done()
        , 0
