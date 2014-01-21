cropme Angular Module
========================

Drag and drop or select an image, crop it and get the blob, that you can use to upload wherever and however you want

Install
-------

Copy the cropme.js and cropme.css file into your project and add the following line with the correct path:

		<script src="/path/to/scripts/cropme.js"></script>
		<script src="/path/to/scripts/cropme.css"></script>


Alternatively, if you're using bower, you can add this to your component.json (or bower.json):

		"cropme": "git://github.com/standup75/cropme.git"

And add this to your HTML:

    <script src="components/cropme/cropme.js"></script>
    <script src="components/cropme/cropme.css"></script>


Usage
-----
		<cropme
			width="640"
			height="400"
			ratio="1"
			icon-class=""
			type="png"
			destination-width="300">
		</cropme>

- width: width of the container. The image you want to crop will be reduced to this width
- height: (optional) height of the container. Default is 300
- icon-class: (optional) css class of the icon to be set in the middle of the drop box
- type: (optional) png or jpeg (might work with webm too, haven't tried it)
- ratio: (optional) destination-height = ratio x destination-width. So you can either define ratio, or add a destination-height parameter, or none.
- destination-width: (optional) target (cropped) picture width
- destination-height: (optional) target (cropped) picture height. Cannot be set if ratio is set.

And don't forget to add the module to your application

		angular.module("myApp", ["cropme"])

You can choose to hide the default ok and cancel buttons by adding this to your css

		#cropme-cancel, #cropme-ok { display: none; }

Events Sent
----------

The blob will be sent through an event, to catch it inside your app, you can do like this:

		$scope.$on("cropme:done", function(e, blob) { /* do something with this blob */ });

Also cropme will send an event when a picture has been chosen by the user, so you can do something like

		$scope.$on("cropme:loaded", function(width, height) { /* do something when the image is loaded */ });

Events Received
---------------

And you can trigger ok and cancel action by broadcasting the events cropme:cancel and cropme:ok, for example:

		$scope.$broadcast("cropme:cancel");

Demo
----

Try the (very simple) demo. How to run the demo? Simple...

		git clone git@github.com:standup75/cropme.git
		cd cropme
		npm install && bower install
		grunt server

This should open your browser at http://localhost:9000 where the demo now sits.
