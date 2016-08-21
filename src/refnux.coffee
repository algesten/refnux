
{Component, PropTypes} = require 'react'

# singleton during render
provider = null

# test if object is an object (not array)
isobject = (o) -> !!o and typeof o == 'object' and !Array.isArray(o)

class Provider extends Component

    constructor: (props) ->
        super
        throw new Error("Provider does not support children") if props.children
        @state = props.state
        @app   = props.app

    render: ->
        provider = this # set singleton for connect function
        try
            @app() # render with current state
        catch err
            throw err
        finally
            provider = null # remove when done

    dispatch: (val, action) =>

        # only one at a time
        throw new Error("dispatch in dispatch is not allowed") if @dispatching
        @dispatching = true

        # current state
        state = @state

        # allow one arg action that takes entire state
        if arguments.length == 1
            action = val
            val = state

        # sanity check
        unless val == state
            throw new Error("Dispatched value must be an object") unless isobject(val)
            for k, v of val
                unless state.hasOwnProperty(k)
                    throw new Error("Dispatched key (#{k}) missing in state")
                unless state[k] == v
                    throw new Error("Dispatched value for key (#{k}) differs in state")

        # execute the action
        try
            newval = action val, @dispatch
        catch err
            throw err
        finally
            @dispatching = false

        # sanity check 2
        throw new Error("Action must return an object") unless isobject(newval)
        for k, v of newval
            unless state.hasOwnProperty(k)
                throw new Error("Action returned key (#{k}) missing in state")

        # create a new state
        newstate = Object.assign {}, state, newval

        # update the state
        @setState newstate


# app and state are required
Provider.propTypes = {
    app:   PropTypes.func.isRequired
    state: PropTypes.object.isRequired
}

# connected stateless functions receive a dispatch function to execute actions
connect = (viewfn) -> ->

    unless provider
        throw new Error("No provider in scope. View function outside Provider?")

    # invoke the actual view function
    viewfn(provider.dispatch)(provider.state)

module.exports = {connect, Provider}
