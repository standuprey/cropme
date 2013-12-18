audiometa Angular Module
========================

Get metadata information of the MP3, WAV, AIFF files being uploaded.

It includes a test suite and a demo.
The demo is necessary to fully test the features, since there is no way to write end-2-end tests for file upload (https://github.com/angular/angular.js/issues/2686)

Install
-------

Copy the audiometa.js file into your project and add the following line with the correct path:

		<script src="/path/to/scripts/audiometa.js"></script>

For the webworker version, you will need to copy audiometaWorker.js instead, but only import audiometaWorker.js like so:

		<script src="/path/to/scripts/audiometaWorker.js"></script>


Alternatively, if you're using bower, you can add this to your component.json (or bower.json):

		"audiometa": "git://github.com/standup75/audiometa.git"

And add this to your HTML:

    <script src="components/audiometa/audiometa.js"></script>

Or, if you want to use the web worker version:

    <script src="components/audiometa/audiometaWorker.js"></script>

Usage
-----

Register for the change event on the input tag in your html:

		<input type="file" onchange="angular.element(this).scope().setFile(this)"/>

Add the "audiometa" module to your app (or "audiometaWorker" if you want to use the web worker version):

		module("myapp", ["audiometa"]);
 
Inject AudioParser (or "AudioParserWorker") into your controller and implement setFile:

		angular.module("myapp").controller "ctrl", ["AudioParser", function (AudioParser) {

			$scope.setFile = function(file){
				AudioParser.getInfo(file).then(function(fileInfo){
					// do something here
				});
			}

		}]

Demo
----

For more details and an example with multiple files, try the (very simple) demo. How to run the demo? Simple...

		git clone git@github.com:standup75/audiometa.git
		cd audiometa
		npm install && bower install
		grunt server

This should open your browser at http://localhost:9000 where the demo now sits.

The example's controller includes a function called getfileInfoByBatch. This is important if you plan on selecting a large amount of files. It sends the messages to the webworker by batch of 10, avoiding issues that occur when you overload the web worker with tasks.