
{createStore, Provider, connect} = require '../src/refnux'

{createFactory, createElement} = require 'react'
{renderToString} = require 'react-dom/server'
{div} = require('react').DOM
pf = createFactory Provider


describe 'Provider', ->

    {createFactory} = require 'react'
    {renderToString} = require 'react-dom/server'
    {div} = require('react').DOM
    pf = createFactory Provider
    app = spy -> div(null, 'abc')
    store = createStore(panda:42)

    it 'requires a store and an app function', ->
        pel = pf({app, store})
        pel2 = pf({ children: app, store })
        assert pel.props.app == pel2.props.children

    it 'does not allow to define app as both property and child', ->
        pel = pf({app, store, children: app})
        assert.throws(
            -> renderToString pel
        ,
            'Provider: can\'t set app component both as property and child'
        )

    it 'invokes the app function on render', ->
        pel = pf({app, store})
        html = renderToString pel
        eql html, '<div data-reactroot="" data-reactid="1" '+
            'data-react-checksum="-1466167168">abc</div>'
        eql app.args, [[]]

    it 'rerenders on store change', ->
        pel = pf({children: app, store})
        renderToString pel
        store.dispatch -> panda:43
        eql app.args, [[],[]]

