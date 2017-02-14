
{createStore, Provider, connect} = require '../src/refnux'

{createFactory} = require 'react'
{renderToString} = require 'react-dom/server'
{div} = require('react').DOM
pf = createFactory Provider

describe 'createStore', ->

    ['subscribe', 'dispatch'].forEach (fn) ->
        it "makes a store with #{fn}", ->
        o = createStore()
        eql typeof(o[fn]), 'function'
        eql typeof(o.state), 'object'

    it 'makes an initial empty state', ->
        o = createStore()
        eql o.state, {}

    it 'takes an initial state as arg', ->
        o = createStore(panda:42)
        eql o.state, panda:42

    it 'cant write to store.state', ->
        o = createStore(panda:42)
        assert.throws (->o.state = {}), 'store.state is read only'

    describe 'dispatch', ->

        o = st = null
        beforeEach ->
            st = panda:42
            o = createStore st

        it 'doesnt modify the incoming state', ->
            assert st == o.state, 'initial state is unmodified'

        it 'takes an action function as argument', ->
            o.dispatch -> {}
            eql o.state, panda:42

        it 'doesnt change the state when no mutation', ->
            o.dispatch -> {}
            assert o.state == st

        it 'doesnt change the state when no change', ->
            o.dispatch -> panda:42
            assert o.state == st

        it 'refuses any other type of arg', ->
            assert.throws (->o.dispatch null), 'Action must be a function'
            assert.throws (->o.dispatch {  }), 'Action must be a function'

        it 'requires action to return an object', ->
            act = -> null
            assert.throws (->o.dispatch act), 'Action must return an object'

        it 'mixes in action return into state', ->
            act = -> panda:43
            o.dispatch act
            eql o.state, panda:43
            eql st, panda:42

        it 'doesnt modify state objects', ->
            act = -> panda:43
            o.dispatch act
            assert st != o.state, 'not same state'

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
