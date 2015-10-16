cropme Angular Module
========================

Drag and drop or select an image, crop it and get the blob, that you can use to upload wherever and however you want
[Demo here!](http://standupweb.net/cropmedemo)

Install
-------

Copy the cropme.js and cropme.css files into your project and add the following line with the correct path:

		<script src="/path/to/scripts/cropme.js"></script>
		<link rel="stylesheet" href="/path/to/scripts/cropme.css">


Alternatively, if you're using bower, you can add this to your component.json (or bower.json):

		"angular-cropme": "~0.3.6"

Or simply run

		bower install angular-cropme

Check the dependencies to your html (unless you're using wiredep):

		<script src="components/angular/angular.js"></script>
		<script src="components/angular-sanitize/angular-sanitize.js"></script>
		<script src="components/angular-touch/angular-touch.js"></script>
		<script src="components/angular-superswipe/superswipe.js"></script>

And (unless you're using wiredep):

		<script src="components/angular-cropme/cropme.js"></script>

And the css:

		<link rel="stylesheet" href="components/angular-cropme/cropme.css">

Add the module to your application

		angular.module("myApp", ["cropme"])

You can choose to hide the default ok and cancel buttons by adding this to your css

		#cropme-cancel, #cropme-ok { display: none; }


Usage
-----
		<cropme
			width="640"
			height="400"
			ratio="1"
			icon-class=""
			type="png"
			destination-width="300"
			id="cropme1"
			ok-label="Ok"
			src="images/myImage.jpg"
			cancel-label="Cancel">
		</cropme>

Attributes
----------

Note: all local scope properties are defined using "@", meaning it accesses the string value, if you want a variable to be accessed, you need to use interpolation, for example, if the src of the image is in the controller variable imgSrc, you can use the src attributes like this: `src="{{imgSrc}}"`

#### width (optional)
Set the width of the crop space container. Omit the width to make the box fit the size of the parent container. The image you want to crop will be reduced to this width and the directive will throw an error if the image to be cropped is smaller than this width.
#### height (optional, default: 300px)
Set the height of the container. The image to be cropped cannot be less than this measurement.
#### icon-class: (optional)
CSS class of the icon to be set in the middle of the drop box
#### type (optional)
Valid values are 'png' or 'jpeg' (might work with webm too, haven't tried it)
#### destination-width (optional)
Set the target (cropped) picture width.
		destination-width="250"
the cropped image will have a width of 250px.
#### destination-height (optional)
Set the target (cropped) picture height. Cannot be set if ratio is set.
		destination-height="250"
the cropped image will have a height of 250px.
#### ratio (optional, requires destination-width to be set)
Constrict the crop area to a fixed ratio. Here are some common examples: 1 = 1:1 ratio, 0.75 = 4:3 ratio and 0.5 = 2:1 ratio.
```
ratio = destination-height / destination-width
destination-height = ratio x destination-width
```
WARNING: When setting a ratio attribute you must not also set a destination-height attribute or an error will be thrown.

To control the size of the cropped image you can use a combination of destination-width and ratio or destination-width and destination-height.

#### src (optional)
url of the image to preload (skips file selection). Note that if the url is not local, you might get the following error:
`Error: [$sce:insecurl] Blocked loading resource from url not allowed by $sceDelegate policy`
In this case make sure that wrap the source string with `$sce.trustAsResourceUrl` in your controller. You can see the controller of the demo for an example
#### send-original (default: false)
If you want to send the original file
#### send-cropped (default: true)
If you want to send the cropped image
#### id (optional)
Add id to cropme to tell which cropme element sent the done/ loaded event
#### ok-label
Label for the ok button (default: "Ok")
#### cancel-label
Label for the cancel button (default: "Cancel")

Events Sent
----------

The blob will be sent through an event, to catch it inside your app, you can do it like this:

		$scope.$on("cropme:done", function(ev, result, canvasEl) { /* do something */ });

The blob will be sent also through a progress event when you move or resize the area:

		$scope.$on("cropme:progress", function(ev, result, canvasEl) { /* do something */ });

The module will also send an event when a picture has been chosen by the user:

		$scope.$on("cropme:loaded", function(ev, width, height) { /* do something when the image is loaded */ });

Where result is an object with the following keys:

		x: x position of the crop image relative to the original image
		y: y position of the crop image relative to the original image
		height: height of the crop image
		width: width of the crop image
		croppedImage: crop image as a blob
		originalImage: original image as a blob
		destinationHeight: height of the cropped image
		destinationWidth: width of the cropped image
		filename: name of the original file


Events Received
---------------

And you can trigger ok and cancel action by broadcasting the events cropme:cancel and cropme:ok, for example:

		$scope.$broadcast("cropme:cancel");

So, now, how do I send this image to my server?
-----------------------------------------------

		scope.$on("cropme:done", function(ev, blob) {
			var xhr = new XMLHttpRequest;
			xhr.setRequestHeader("Content-Type", blob.type);
			xhr.onreadystatechange = function(e) {
				if (this.readyState === 4 && this.status === 200) {
					return console.log("done");
				} else if (this.readyState === 4 && this.status !== 200) {
					return console.log("failed");
				}
			};
			xhr.open("POST", url, true);
			xhr.send(blob);
		});


Demo
----

To run it locally, run:
`npm install & bower install`
build the project
`grunt`
then go to the demo folder
`cd demo`
and install npm and bower again here
`npm install & bower install`
and start the demo
`grunt serve`
You should be able to then go on your browser at localhost:9001

If you want to try and see what this is all about:
[Demo here!](http://standupweb.net/cropmedemo)
