
{Component, PropTypes, createElement} = require 'react'

# singleton during render
provider = null

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
        return unless change

        # create a new state
        newstate = Object.assign {}, state, newval

        # update the state
        setState newstate

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
        throw new Error("Provider does not support children") if props.children
        {@store, @app} = props
        @state = props.store.state

    componentDidMount: =>
        # start listening to changes in the store
        @unsubscribe = @store.subscribe (newstate) => @setState(newstate)

    componentWillUnmount: =>
        # stop listening to the store
        @unsubscribe?()
        @unsubscribe = null

    render: ->
        provider = this # set singleton for connect function
        try
            @app() # render with current state
        catch err
            throw err
        finally
            # render pass of JSX is synchronous, child components are
            # rendered *after* the render function. we cleanup in
            # a timeout, because callback of @setState doesn't
            # happen on first render.
            (setImmediate ? setTimeout) (-> provider = null), 0


storeShape = PropTypes.shape(
    subscribe: PropTypes.func.isRequired,
    dispatch:  PropTypes.func.isRequired,
    state:     PropTypes.object.isRequired
)

# app and state are required
Provider.propTypes = {
    app:   PropTypes.func.isRequired
    store: storeShape.isRequired
}

# internal wrapping component to keep track of the
# provider when doing rerender out of scope
class Connected extends Component

    constructor: (props) ->
        super
        {@viewfn} = props

    render: =>
        # store away the global provider locally in case we
        # get a local re-render
        @provider = provider if provider

        # and use the local ref always
        local = @provider

        unless local
            throw new Error("No provider in scope. First render must be from Provider")

        state = local.store.state
        dispatch = local.store.dispatch

        # invoke the actual view function
        @viewfn(state, dispatch, @props.outerprops)



# connected stateless functions receive a dispatch function to execute actions
connect = (viewfn) ->

    # ensure arg is good
    throw new Error("connect requires a function argument") unless typeof(viewfn) == 'function'

    # the wrapping Connected element keeps track of the provider when
    # rerender out of scope
    (props) -> createElement Connected, {viewfn, outerprops:props}

module.exports = {createStore, Provider, connect}
