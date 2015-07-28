"use strict"
module.exports = (grunt) ->
  
  # Load grunt tasks automatically
  require("load-grunt-tasks") grunt
  
  # Define the configuration for all the tasks
  grunt.initConfig
    copy: require "./tasks/options/copy"
    clean: require "./tasks/options/clean"
    coffee: require "./tasks/options/coffee"
    compass: require "./tasks/options/compass"
    connect: require "./tasks/options/connect"
    karma: require "./tasks/options/karma"
    concat: require "./tasks/options/concat"
    ngAnnotate: require "./tasks/options/ngannotate"
    ngdocs: require "./tasks/options/ngdocs"
    watch: require "./tasks/options/watch"

  grunt.registerTask "build", [
    "clean"
    "compass"
    "coffee"
    "concat"
    "ngAnnotate"
    "ngdocs"
    "copy"
    "connect:test"
    #"karma:unit"
  ]

  grunt.registerTask "debug", [
    "clean"
    "compass"
    "coffee"
    "concat"
    "ngAnnotate"
    "ngdocs"
    "connect:test"
    #"karma:debug"
  ]
  grunt.registerTask "serve", [
    "build"
    "watch"
  ]
  grunt.registerTask "default", ["build"]
  return