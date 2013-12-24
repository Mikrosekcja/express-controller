debug   = require "debug"
path    = require "path"
_       = require "lodash"

$       = debug "express-controller"

class Controller
  constructor : (@options = {}) ->

    _(@options).defaults
      routes  : {}

    @routes     = @options.routes

    # Root directory for controller's modules (see below)
    if not @options.directory? and not @options.name then throw Error """
      Provide name or directory for this new controller.
    """
    directory   = @options.directory or
                  path.resolve require.main.filename, "..", "controllers/", @options.name

    for name, route of @routes
      ###
      Route can be provided in canonical form as hash:
        method  : "GET"
        url     : "/foos/:foo_id"
        action  : (req, res) -> ...
        options : {}

      `url` can be an array of strings for multiple paths
      `action` is optional. It can be a function taking req and res. It is suppose to handle the request (send results to client). If it's a string, then Controller will require it resolving path from `directory` option. If it's `undefined` then Controller will act as if it's a string equal to `name` of of this route (ie. attribute name of routes hash).

      ###

      if typeof route is "object"
        {
          method
          url
          action  # Optional function (req, res)
          options # Optional - can be utilised in extensions of controller
        } = route

      # or in short form as string: "GET  /foo/:foo_id"
      else if typeof route is "string"
        [
          method
          url
        ] = route.split /\s+/

      method  = method.toLowerCase()
      if not method in [
        "get"
        "post"
        "put"
        "delete"
      ] then throw Error """
        Invalid method (#{method}) for route '#{name}'
        Method must be one of 'GET', 'POST', 'PUT', 'DELETE'
      """

      # In canonical form url is an array of strings, usually one :)
      if typeof url is "string" then url = [ url ]
      if _.isArray url then url = _.filter url, (e) -> typeof e is "string"
      if not url.length then throw Error """
        Invalid URL for route '#{name}'
        URL must be a string or array of strings.
      """

      if not action? then action = name
      if typeof action is "string"
        module_path = path.resolve directory, action
        $ "Loading function for %s (%s %j) from %s", name, method, url, module_path
        action = require module_path

      options ?= {}

      if typeof action is "function" then action = action.bind @, options
      else throw Error """
        Invalid action for route (#{name}).
        Action must be a function with two parameters (options, req, res)
        or a string resolving to module exporting such a function.
      """

      # Lets cast it to canonical form
      route   = {
        method
        url
        action
        options
      }
      @routes[name] = route
    
  plugInto    : (app) ->
    # console.dir @
    for name, route of @routes
      {
        method
        url
        action
      } = route
      for single_url in url
        $ "Plugging %s into app.%s %s", name, method, single_url
        app[method] single_url, action
      
module.exports = Controller