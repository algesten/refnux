
{Component, PropTypes} = require 'react'

# singleton during render
_provider = null

# test if object is an object (not array)
isobject = (o) -> !!o and typeof o == 'object' and !Array.isArray(o)

class Provider extends Component

    constructor: (props) ->
        super
        throw new Error("Provider does not support children") if props.children
        @state = props.state
        @app   = props.app

    render: ->
        _provider = this # set singleton for connect function
        try
            @app() # render with current state
        catch err
            throw err
        finally
            _provider = null # remove when done

# app and state are required
Provider.propTypes = {
    app:   PropTypes.func.isRequired
    state: PropTypes.object.isRequired
}

# connected stateles functions receive a dispatch function to run actions
connect = (viewfn) -> ->

    # save provider for this render pass
    provider = _provider

    # the state to dispatch
    state = provider.state

    # the local dispatcher
    dispatch = (val, action) ->
        throw new Error("Dispatched value must be an object") unless isobject(val)

        # sanity check
        for k, v of val
            unless state.hasOwnProperty(k)
                throw new Error("Dispatched key (#{k}) missing in state")
            unless state[k] == v
                throw new Error("Dispatched value for key (#{k}) differs in state")

        # execute the action
        newval = action val

        # sanity check 2
        throw new Error("Action must return an object") unless isobject(newval)
        for k, v of newval
            unless state.hasOwnProperty(k)
                throw new Error("Action returned key (#{k}) missing in state")

        # create a new state
        newstate = Object.assign {}, state, newval

        # update the state
        provider.setState newstate

    viewfn(dispatch)(state)

module.exports = {connect, Provider}
