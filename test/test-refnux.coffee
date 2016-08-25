
{createStore, Provider, connect} = require '../src/refnux'

{createFactory} = require 'react'
{renderToString} = require 'react-dom/server'
{div} = require('react').DOM
pf = createFactory Provider

describe 'createStore', ->

    ['subscribe', 'dispatch', 'getState'].forEach (fn) ->
        it "makes a store with #{fn}", ->
        o = createStore()
        eql typeof(o[fn]), 'function'

    it 'makes an initial empty state', ->
        o = createStore()
        eql o.getState(), {}

    it 'takes an initial state as arg', ->
        o = createStore(panda:42)
        eql o.getState(), panda:42

    describe 'dispatch', ->

        o = st = null
        beforeEach ->
            st = panda:42
            o = createStore st

        it 'doesnt modify the incoming state', ->
            assert st == o.getState(), 'initial state is unmodified'

        it 'takes an action function as argument', ->
            o.dispatch -> {}
            eql o.getState(), panda:42

        it 'doesnt change the state when no mutation', ->
            o.dispatch -> {}
            assert o.getState() == st

        it 'doesnt change the state when no change', ->
            o.dispatch -> panda:42
            assert o.getState() == st

        it 'refuses any other type of arg', ->
            assert.throws (->o.dispatch null), 'Action must be a function'
            assert.throws (->o.dispatch {  }), 'Action must be a function'

        it 'requires action to return an object', ->
            act = -> null
            assert.throws (->o.dispatch act), 'Action must return an object'

        it 'mixes in action return into state', ->
            act = -> panda:43
            o.dispatch act
            eql o.getState(), panda:43
            eql st, panda:42

        it 'doesnt modify state objects', ->
            act = -> panda:43
            o.dispatch act
            assert st != o.getState(), 'not same state'

        it 'refuses keys not already present', ->
            act = -> cub:true
            assert.throws (->o.dispatch act), 'Action returned key (cub) missing in state'

        it 'invokes action with (state, dispatch)', ->
            act = spy -> {}
            o.dispatch act
            eql act.args, [[st, o.dispatch]]

        it 'refuses dispatch in dispatch', ->
            act = spy (state, dispatch) ->
                assert.throws (->dispatch (->)), 'dispatch in dispatch is not allowed'
            o.dispatch act
            eql act.args.length, 1



    describe 'subscribe', ->

        o = st = null
        beforeEach ->
            st = panda:42
            o = createStore st

        it 'takes a listener function', ->
            o.subscribe ->

        it 'is angry if not a function', ->
            assert.throws (->o.subscribe null), 'Listener must be a function'

        it 'returns an unsubscribe function', ->
            un = o.subscribe ->
            eql typeof(un), 'function'

        it 'invokes subscriber on state change', ->
            o.subscribe s = spy ->
            o.dispatch -> panda:43
            eql s.args, [[{panda:43},{panda:42}]]
            assert s.args[0][1] == st

        it 'doesnt invokes subscriber after unsubscribe', ->
            un = o.subscribe s = spy ->
            un()
            o.dispatch -> panda:43
            eql s.args, []

        it 'is ok to do multiple unsubscribes', ->
            un = o.subscribe s = spy ->
            un()
            un()
            un()
            un()



describe 'Provider', ->

    {createFactory} = require 'react'
    {renderToString} = require 'react-dom/server'
    {div} = require('react').DOM
    pf = createFactory Provider
    app = spy -> div(null, 'abc')
    store = createStore(panda:42)

    it 'requires a store and an app function', ->
        pel = pf({app, store})

    it 'invokes the app function on render', ->
        pel = pf({app, store})
        html = renderToString pel
        eql html, '<div data-reactroot="" data-reactid="1" '+
            'data-react-checksum="-1466167168">abc</div>'
        eql app.args, [[]]

    it 'rerenders on store change', ->
        pel = pf({app, store})
        renderToString pel
        store.dispatch -> panda:43
        eql app.args, [[],[]]



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
        eql vf.args, [[{panda:42}, store.dispatch]]

    it 'complains if connected function is used outside provider', ->
        app = connect -> div(null, 'abc')
        assert.throws app, 'No provider in scope. View function outside Provider?'

    it 'tidies up after render', ->
        app = connect -> div(null, 'abc')
        pel = pf({app, store})
        renderToString pel
        assert.throws app, 'No provider in scope. View function outside Provider?'
