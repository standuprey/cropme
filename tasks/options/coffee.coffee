module.exports =
  options:
    sourceMap: false
    sourceRoot: ""

  dist:
    files: [
      expand: true
      cwd: "scripts"
      src: "{,*/}*.coffee"
      dest: ".tmp/scripts/"
      ext: ".js"
    ]
