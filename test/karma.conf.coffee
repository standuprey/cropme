# Karma configuration
# http://karma-runner.github.io/0.12/config/configuration-file.html
# Generated on 2014-08-06 using
# generator-karma 0.8.3

module.exports = (config) ->
  config.set
    # base path, that will be used to resolve files and exclude
    basePath: '../'

    # testing framework to use (jasmine/mocha/qunit/...)
    frameworks: ['jasmine']

    # list of files / patterns to load in the browser
    files: [
      'bower_components/angular/angular.js'
      'bower_components/angular-mocks/angular-mocks.js'
      'bower_components/angular-sanitize/angular-sanitize.js'
      'bower_components/angular-touch/angular-touch.js'
      'bower_components/angular-superswipe/superswipe.js'
      'cropme.js'
      'test/spec/**/*.coffee'
    ]

    # list of files / patterns to exclude
    exclude: []

    # web server port
    port: 8081

    # level of logging
    # possible values: LOG_DISABLE || LOG_ERROR || LOG_WARN || LOG_INFO || LOG_DEBUG
    logLevel: config.LOG_INFO

    # Start these browsers, currently available:
    # - Chrome
    # - ChromeCanary
    # - Firefox
    # - Opera
    # - Safari (only Mac)
    # - PhantomJS
    # - IE (only Windows)
    browsers: [
      'Chrome'
    ]

    # Which plugins to enable
    plugins: [
      'karma-phantomjs-launcher'
      'karma-chrome-launcher'
      'karma-jasmine'
      'karma-coverage'
      'karma-coffee-preprocessor'
    ]

    # enable / disable watching file and executing tests whenever any file changes
    autoWatch: true

    # Continuous Integration mode
    # if true, it capture browsers, run tests and exit
    singleRun: false

    colors: true

    preprocessors:
      '**/*.coffee': ['coffee']
      '.tmp/scripts/**/*.js': 'coverage'

    # Uncomment the following lines if you are using grunt's server to run the tests
    # proxies: '/': 'http://localhost:9000/'
    # URL root prevent conflicts with the site root
    # urlRoot: '_karma_'

    reporters: ['progress', 'coverage']
    coverageReporter:
      type: 'html'
      dir: 'docs/coverage/'
