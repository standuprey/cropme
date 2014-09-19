"use strict"

###*
 # @ngdoc service
 # @name elementOffset
 # @requires -
 # @description
 # Get the offset in pixel of an element on the screen
 #
 # @example

```js
angular.module("cropme").directive "myDirective", (elementOffset) ->
	link: (scope, element, attributes) ->
		offset = elementOffset element
		console.log "This directive's element is #{offset.top}px away from the top of the screen"
		console.log "This directive's element is #{offset.left}px away from the left of the screen"
		console.log "This directive's element is #{offset.bottom}px away from the bottom of the screen"
		console.log "This directive's element is #{offset.right}px away from the right of the screen"
```
###
angular.module("cropme").service "elementOffset", ->
	(el) ->
		el = el[0] if el[0]
		offsetTop = 0
		offsetLeft = 0
		scrollTop = 0
		scrollLeft = 0
		width = el.offsetWidth
		height = el.offsetHeight
		while el
			offsetTop += el.offsetTop - el.scrollTop
			offsetLeft += el.offsetLeft - el.scrollLeft
			el = el.offsetParent
		top: offsetTop
		left: offsetLeft
		right: offsetLeft + width
		bottom: offsetTop + height
