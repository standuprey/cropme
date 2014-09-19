# Compiles CoffeeScript to JavaScript
module.exports =
  options:
    sourceMap: false
    sourceRoot: ""

  dist:
    files: [
      expand: true
      cwd: "app/scripts"
      src: "{,*/}*.coffee"
      dest: ".tmp/scripts/"
      ext: ".js"
    ]
