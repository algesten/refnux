
{Component, PropTypes} = require 'react'

# singleton during render
provider = null

# test if object is an object (not array)
isobject = (o) -> !!o and typeof o == 'object' and !Array.isArray(o)

# create a store over a state
createStore = (state) ->

    # store listeners for change
    listeners = []

    # subscribe for store changes
    subscribe = (listener) ->
        isSubscribed = true
        listeners.push listener
        unsubscribe = ->
            return unless isSubscribed
            isSubscribed = false
            index = listeners.indexOf(listener)
            listeners.splice(index, 1)

    # set a new state and tell all listeners about it
    setState = (newstate) ->
        prevstate = state
        state = newstate
        listeners.forEach (l) -> l state, prevstate

    # get current state
    getState = -> state

    # one at a time
    dispatching = false

    # dispatch the action (function).
    dispatch = (action) ->

        # only one at a time
        throw new Error("dispatch in dispatch is not allowed") if dispatching
        dispatching = true

        # execute the action
        try
            newval = action state, dispatch
        catch err
            throw err
        finally
            dispatching = false

        # sanity check 2
        throw new Error("Action must return an object") unless isobject(newval)
        for k, v of newval
            unless state.hasOwnProperty(k)
                throw new Error("Action returned key (#{k}) missing in state")

        # create a new state
        newstate = Object.assign {}, state, newval

        # update the state
        setState newstate

    # exposed facade
    {subscribe, dispatch, getState}


class Provider extends Component

    constructor: (props) ->
        super
        throw new Error("Provider does not support children") if props.children
        @store = props.store
        @app   = props.app
        @state = props.store.getState()
        @store.subscribe (newstate) => @setState(newstate)

    render: ->
        provider = this # set singleton for connect function
        try
            @app() # render with current state
        catch err
            throw err
        finally
            provider = null # remove when done


storeShape = PropTypes.shape(
    subscribe: PropTypes.func.isRequired,
    dispatch: PropTypes.func.isRequired,
    getState: PropTypes.func.isRequired
)

# app and state are required
Provider.propTypes = {
    app:   PropTypes.func.isRequired
    store: storeShape.isRequired
}

# connected stateless functions receive a dispatch function to execute actions
connect = (viewfn) -> ->

    unless provider
        throw new Error("No provider in scope. View function outside Provider?")

    state = provider.store.getState()
    dispatch = provider.store.dispatch

    # invoke the actual view function
    viewfn(state, dispatch)

module.exports = {createStore, Provider, connect}
