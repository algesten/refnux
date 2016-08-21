
{Component, PropTypes} = require 'react'

# singleton during render
_provider = null

class Provider extends Component

    constructor: (props) ->
        super
        throw new Error("Provider does not support children") if props.children
        @state = props.state
        @app   = props.app

    render: ->
        _provider = this # set singleton for connect function
        try
            @app(@state)
        catch err
            throw err
        finally
            _provider = null # remove when done

# app and state are required
Provider.propTypes = {
    app:PropTypes.func.isRequired
    state:PropTypes.object.isRequired
}

# search in o for a value val and return the corresponding key
findkey = (o, val) ->
    return k for k, v of o when v == val
    throw new Error("Unable to find key for value in state")

# test if object is an object (not array)
isobject = (o) -> !!o and typeof o == 'object' and !Array.isArray(o)


# connected stateles functions receive a dispatch function to run actions
connect = (viewfn) -> (state) ->
    throw new Error("Connected function takes a plain object argument") unless isobject(state)
    provider = _provider
    # the local dispatcher
    dispatch = (val, action) ->
        # find the key of the dispatched value
        k = findkey state, val
        newval = action val
        newstate = Object.assign {}, state
        newstate[k] = newval
        provider.setState newstate

    viewfn(dispatch)(state)

module.exports = {connect, Provider}
