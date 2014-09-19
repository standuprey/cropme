module.exports =
	unit:
		configFile: "test/karma.conf.coffee"
		singleRun: true
	debug:
		configFile: "test/karma.conf.coffee"
		singleRun: false
		browsers: ['Chrome']
