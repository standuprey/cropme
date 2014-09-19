module.exports =
  options:
    port: 9001
    
    # Change this to '0.0.0.0' to access the server from outside.
    hostname: "localhost"
    livereload: 35729

  livereload:
    options:
      open: true
      middleware: (connect) ->
        [
          connect.static(".tmp")
          connect().use("/bower_components", connect.static("./bower_components"))
          connect.static("app")
        ]