"use strict"
module.exports = (grunt) ->
  
  # Load grunt tasks automatically
  require("load-grunt-tasks") grunt
  
  # Define the configuration for all the tasks
  grunt.initConfig
    clean: require "./tasks/options/clean"
    coffee: require "./tasks/options/coffee"
    connect: require "./tasks/options/connect"
    copy: require "./tasks/options/copy"
    watch: require "./tasks/options/watch"
    useminPrepare: require "./tasks/options/useminPrepare"
    usemin: require "./tasks/options/usemin"

  grunt.registerTask "serve", [
    "clean"
    "coffee"
    "connect:livereload"
    "watch"
  ]

  grunt.registerTask "build", [
    "clean"
    "useminPrepare"
    "coffee"
    "concat"
    "copy"
    "usemin"

  ]

  grunt.registerTask "default", ["build"]
  return