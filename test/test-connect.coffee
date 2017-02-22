
{createStore, Provider, connect} = require '../src/refnux'

{createFactory, Component} = require 'react'
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
        eql vf.args, [[{panda:42}, store.dispatch, {}]]

    it 'passes properties to wrapped component', ->
        props = { some: 'prop' }
        component = connect vf = spy -> div(null, 'abc')
        app = -> component(props)
        pel = pf({app, store})
        eql vf.args, []
        html = renderToString pel
        eql vf.args, [[{panda:42}, store.dispatch, props]]

    it 'complains if connected function is used outside provider', ->
        app = connect (state, dispatch, props) -> div(null, 'abc')
        fail = -> renderToString div null, app()
        assert.throws fail, 'No provider in scope.'

    it 'connects nested sub-components', ->
        nspy = null
        nested = connect nspy = spy (state) -> div(null, "l2 #{state.panda}")
        app = connect (state) -> div(null, "l1 #{state.panda}", nested())
        pel = pf({app, store})
        html = renderToString pel
        eql html, '<div data-reactroot="" data-reactid="1" data-react-checksum="-819321188"><!-- react-text: 2 -->l1 42<!-- /react-text --><div data-reactid="3">l2 42</div></div>'
        eql nspy.args, [[store.state, store.dispatch, {}]]
