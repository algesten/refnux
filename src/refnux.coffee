
{Component, PropTypes, createElement} = require 'react'

# test if object is an object (not array)
isobject = (o) -> !!o and typeof o == 'object' and !Array.isArray(o)

# create a store over a state
createStore = (state = {}) ->

    # store listeners for change
    listeners = []

    # subscribe for store changes
    subscribe = (listener) ->

        # check it's actually a listener
        throw new Error("Listener must be a function") unless typeof(listener) == 'function'

        # remember it
        listeners.push listener

        # return unsubscribe function
        ->
            index = listeners.indexOf(listener)
            return if index < 0
            listeners.splice(index, 1)

    # set a new state and tell all listeners about it
    setState = (newstate) ->
        prevstate = state
        state = newstate
        listeners.forEach (l) -> l state, prevstate

    # one at a time
    dispatching = false

    # dispatch the action (function).
    dispatch = (action) ->

        # must be a function
        throw new Error("Action must be a function") unless typeof action == 'function'

        # only one at a time
        throw new Error("dispatch in dispatch is not allowed") if dispatching
        dispatching = true

        # execute the action
        try
            newval = action state, dispatch

            if newval and typeof(newval.then) is 'function'
                dispatching = false
                return newval.then(
                    (val) -> dispatch(-> val)
                )

        catch err
            throw err
        finally
            dispatching = false

        # sanity check 2
        throw new Error("Action must return an object") unless isobject(newval)
        change = false # check if we have a change
        for k, v of newval
            unless state.hasOwnProperty(k)
                throw new Error("Action returned key (#{k}) missing in state")
            change |= state[k] != v

        # no change?
        return state unless change

        # create a new state
        newstate = Object.assign {}, state, newval

        # update the state
        setState newstate

        # return new state
        newstate

    # exposed facade
    store = {subscribe, dispatch}

    # state property read only getter
    Object.defineProperty store, 'state',
        enumerable: true
        get: -> state
        set: -> throw new Error("store.state is read only")

    # the finished store
    store


class Provider extends Component

    constructor: (props) ->
        super
        if Array.isArray(props.children) and props.children.length > 1
            throw new Error("Provider does not support multiple children")
        {@store, @app} = props

        if props.children?
            throw new Error 'Provider: can\'t set app component both as property and child' if @app
            @app = props.children
            if false and typeof(props.children) isnt 'function'
                @app = -> props.children

        @state = props.store.state

    getChildContext: => { store: this.props.store }

    componentDidMount: =>
        # start listening to changes in the store
        @unsubscribe = @store.subscribe (newstate) => @setState(newstate)

    componentWillUnmount: =>
        # stop listening to the store
        @unsubscribe?()
        @unsubscribe = null

    render: =>
        if typeof(@app) is 'function'
            return @app()
        return @app


storeShape = PropTypes.shape(
    subscribe: PropTypes.func.isRequired,
    dispatch:  PropTypes.func.isRequired,
    state:     PropTypes.object.isRequired
)

# app and state are required
Provider.propTypes = {
    app:   PropTypes.func
    store: storeShape.isRequired
}

Provider.childContextTypes = {
    store: storeShape.isRequired
}

# injection point for getting newly created elements
proxy = doproxy: (v) -> v

# connected stateless functions receive a dispatch function to execute actions
connect = (viewfn) ->

    # ensure arg is good
    throw new Error("connect requires a function argument") unless typeof(viewfn) == 'function'

    # create a unique instance of Connected for each connected component
    # this is used to wire up the store via context.
    Connected = (props, context) ->

        throw new Error("No provider in scope.") unless context.store

        # the current state/dispatch
        {state, dispatch} = context.store

        # invoke the actual view function
        viewfn(state, dispatch, props)

    # this is the magic
    Connected.contextTypes = {
        store: storeShape.isRequired
    }

    # receive incoming props, and create instance of the new Connected
    (props) -> proxy.doproxy createElement Connected, (props ? {})

module.exports = {createStore, Provider, connect, proxy}
