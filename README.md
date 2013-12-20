cropme Angular Module
========================

Drag and drop or select an image, crop it and get the blob, that you can use to upload wherever and however you want

Install
-------

Copy the cropme.js file into your project and add the following line with the correct path:

		<script src="/path/to/scripts/cropme.js"></script>


Alternatively, if you're using bower, you can add this to your component.json (or bower.json):

		"audiometa": "git://github.com/standup75/cropme.git"

And add this to your HTML:

    <script src="components/audiometa/cropme.js"></script>


Usage
-----
		<cropme
			width="640"
			height="400"
			autocrop="true"
			ratio="1"
			destination-width="300">
		</cropme>

- width: width of the container. The image you want to crop will be reduced to this width
- height: (optional) height of the container.
- autocrop: (optional) The image you want to crop will be reduced to the value of height if true
- ratio: (optional) destination-height = ratio x destination-width. So you can either define ratio, or add a destination-height parameter, or none.

Demo
----

For more details and an example with multiple files, try the (very simple) demo. How to run the demo? Simple...

		git clone git@github.com:standup75/audiometa.git
		cd cropme
		npm install && bower install
		grunt server

This should open your browser at http://localhost:9000 where the demo now sits.
