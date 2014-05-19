superswipe Angular Module
========================

A copy of angular $swipe directive. I just removed a feature that enables vertical swipe

Install
-------

Copy the superswipe.js file into your project and add the following line with the correct path:

		<script src="/path/to/scripts/superswipe.js"></script>

Alternatively, if you're using bower, you can add this to your component.json (or bower.json):

		"angular-superswipe": "git://github.com/standup75/superswipe.git"

Or simply run

		bower install angular-superswipe

And add this to your HTML:

    <script src="components/superswipe/superswipe.js"></script>

Usage
-----

Refer to [https://docs.angularjs.org/api/ngTouch/service/$swipe]https://docs.angularjs.org/api/ngTouch/service/$swipe
Just ignore this section:

> If the vertical distance is greater, this is a scroll, and we let the browser take over. A cancel event is sent.

And don't forget to add the module to your application

		angular.module("myApp", ["ngTouch", "superswipe"])

Demo
----

Try the (very simple) demo. How to run the demo? Simple...

		git clone git@github.com:standup75/superswipe.git
		cd superswipe
		npm install && bower install
		grunt server

This should open your browser at http://localhost:9000 where the demo now sits.
