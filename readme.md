Express Controller
==================

Yet another approach to MVC for Express.

Usage
-----

``` coffee-script
Controller = require "express-controller"

module.exports = new Controller
  name  : "home"
  routes  :
    display :
      method  : "GET"
      url     : "/"
      action  : (options, req, res) -> res.send "Welcome home!"
```

About
-----

This is generally a basis for specialized controller classes, like ModelController. One can use it as it is though.