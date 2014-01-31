'use strict';
var lrSnippet = require('grunt-contrib-livereload/lib/utils').livereloadSnippet;
var mountFolder = function (connect, dir) {
  return connect.static(require('path').resolve(dir));
};

module.exports = function (grunt) {
  // load all grunt tasks
  require('matchdep').filterDev('grunt-*').forEach(grunt.loadNpmTasks);

  // configurable paths
  var yeomanConfig = {
    app: 'src',
    demo: 'demo',
    name: 'cropme',
    dist: 'dist',
  };

  try {
    yeomanConfig.app = require('./bower.json').appPath || yeomanConfig.app;
  } catch (e) {}

  grunt.initConfig({
    yeoman: yeomanConfig,
    watch: {
      coffee: {
        files: ['<%= yeoman.app %>/{,*/}*.coffee'],
        tasks: ['coffee:dist', 'concat']
      },
      coffeeDemo: {
        files: ['<%= yeoman.demo %>/scripts/{,*/}*.coffee'],
        tasks: ['coffee:demo']
      },
      coffeeTest: {
        files: ['test/spec/{,*/}*.coffee'],
        tasks: ['coffee:test']
      },
      compass: {
        files: ['styles/{,*/}*.{scss,sass}'],
        tasks: ['compass']
      },
      livereload: {
        files: [
          '.tmp/**/*.js',
          '.tmp/styles/{,*/}*.css',
          '<%= yeoman.app %>/{,*/}*.html',
          '<%= yeoman.demo %>/styles/{,*/}*.css',
          '<%= yeoman.demo %>/images/{,*/}*.{png,jpg,jpeg,gif,webp,svg}'
        ],
        tasks: ['livereload']
      }
    },
    connect: {
      options: {
        port: 9000,
        // Change this to '0.0.0.0' to access the server from outside.
        hostname: 'localhost'
      },
      livereload: {
        options: {
          middleware: function (connect) {
            return [
              lrSnippet,
              mountFolder(connect, '.tmp'),
              mountFolder(connect, yeomanConfig.demo),
              mountFolder(connect, yeomanConfig.dist)
            ];
          }
        }
      },
      test: {
        options: {
          middleware: function (connect) {
            return [
              mountFolder(connect, '.tmp'),
              mountFolder(connect, 'test')
            ];
          }
        }
      }
    },
    open: {
      server: {
        url: 'http://localhost:<%= connect.options.port %>'
      }
    },
    clean: {
      dist: {
        files: [{
          dot: true,
          src: [
            '.tmp',
            '<%= yeoman.dist %>/*',
            '!<%= yeoman.dist %>/.git*'
          ]
        }]
      },
      server: '.tmp'
    },
    karma: {
      unit: {
        configFile: 'karma.conf.js',
        singleRun: true
      }
    },
    coffee: {
      dist: {
        files: [{
          expand: true,
          cwd: '<%= yeoman.app %>',
          src: '{,*/}*.coffee',
          dest: '.tmp/src/scripts',
          ext: '.js'
        }]
      },
      demo: {
        files: [{
          expand: true,
          cwd: '<%= yeoman.demo %>/scripts',
          src: '{,*/}*.coffee',
          dest: '.tmp/demo/scripts',
          ext: '.js'
        }]
      },
      test: {
        files: [{
          expand: true,
          cwd: 'test/spec',
          src: '{,*/}*.coffee',
          dest: '.tmp/spec',
          ext: '.js'
        }]
      }
    },
    compass: {
      options: {
        sassDir: 'styles',
        cssDir: '.tmp/styles',
        raw: 'http_images_path = "images/"\ngenerated_images_dir = ".tmp/images"\nhttp_generated_images_path = "../images/"',
        // This doesn't work with relative paths.
        relativeAssets: false
      },
      dist: {},
      server: {
        options: {
          debugInfo: true
        }
      }
    },
    concat: {
      dist: {
        files: {
          '<%= yeoman.dist %>/<%= yeoman.name %>.js': [
            '.tmp/src/scripts/init.js', '.tmp/src/scripts/{,*/}*.js'
          ]
        }
      }
    },
    copy: {
      dist: {
        files: [{
          expand: true,
          cwd: '<%= yeoman.dist %>',
          dest: '',
          src: [ '*.js' ]
        }, {
          expand: true,
          cwd: '.tmp/styles',
          dest: '',
          src: [ '*.css' ]
        }]
      }
    }
  });

  grunt.renameTask('regarde', 'watch');

  grunt.registerTask('server', [
    'clean:server',
    'coffee',
    'concat',
    'compass:server',
    'copy',
    'livereload-start',
    'connect:livereload',
    'open',
    'watch'
  ]);

  grunt.registerTask('test', [
    'clean:server',
    'coffee:dist',
    'coffee:test',
    'concat',
    'copy',
    'connect:test',
    'karma'
  ]);

  grunt.registerTask('build', [
    'clean:dist',
    'coffee',
    'compass:dist',
    'concat',
    'copy',
    'test'
  ]);

  grunt.registerTask('default', ['build']);
};
