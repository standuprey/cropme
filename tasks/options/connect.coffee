module.exports = test:
  options:
    port: 9000
    middleware: (connect) ->
      [
        connect.static(".tmp")
        connect.static("test")
        connect().use("/bower_components", connect.static("./bower_components"))
      ]