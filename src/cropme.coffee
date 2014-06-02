angular.module("cropme", ["ngSanitize", "ngTouch", "superswipe"]).service "elementOffset", ->
	(el) ->
		el = el[0] if el[0]
		offsetTop = 0
		offsetLeft = 0
		while el
			offsetTop += el.offsetTop
			offsetLeft += el.offsetLeft
			el = el.offsetParent
		top: offsetTop
		left: offsetLeft

angular.module("cropme").directive "cropme", ($swipe, $window, $timeout, $rootScope, elementOffset) ->

	minHeight = 100 # if destinationHeight has not been defined, we need a default height for the crop zone
	borderSensitivity = 8 # grab area size around the borders in pixels

	template: """
		<div
			class="step-1"
			ng-show="state == 'step-1'"
			ng-style="{'width': width + 'px', 'height': height + 'px'}">
			<dropbox ng-class="dropClass"></dropbox>
			<div class="cropme-error" ng-bind-html="dropError"></div>
			<div class="cropme-file-input">
				<input type="file"/>
				<div
					class="cropme-button"
					ng-class="{deactivated: dragOver}"
					ng-click="browseFiles()">
						Browse picture
				</div>
				<div class="cropme-or">or</div>
				<div class="cropme-label" ng-class="iconClass">{{dropText}}</div>
			</div>
		</div>
		<div
			class="step-2"
			ng-show="state == 'step-2'"
			ng-style="{'width': width + 'px'}"
			ng-mousemove="mousemove($event)"
			ng-mouseleave="deselect()"
			ng-class="{'col-resize': colResizePointer}">
			<img ng-src="{{imgSrc}}" ng-style="{'width': width + 'px'}"/>
			<div class="overlay-tile" ng-style="{'top': 0, 'left': 0, 'width': xCropZone + 'px', 'height': yCropZone + 'px'}"></div>
			<div class="overlay-tile" ng-style="{'top': 0, 'left': xCropZone + 'px', 'width': widthCropZone + 'px', 'height': yCropZone + 'px'}"></div>
			<div class="overlay-tile" ng-style="{'top': 0, 'left': xCropZone + widthCropZone + 'px', 'right': 0, 'height': yCropZone + 'px'}"></div>
			<div class="overlay-tile" ng-style="{'top': yCropZone + 'px', 'left': xCropZone + widthCropZone + 'px', 'right': 0, 'height': heightCropZone + 'px'}"></div>
			<div class="overlay-tile" ng-style="{'top': yCropZone + heightCropZone + 'px', 'left': xCropZone + widthCropZone + 'px', 'right': 0, 'bottom': 0}"></div>
			<div class="overlay-tile" ng-style="{'top': yCropZone + heightCropZone + 'px', 'left': xCropZone + 'px', 'width': widthCropZone + 'px', 'bottom': 0}"></div>
			<div class="overlay-tile" ng-style="{'top': yCropZone + heightCropZone + 'px', 'left': 0, 'width': xCropZone + 'px', 'bottom': 0}"></div>
			<div class="overlay-tile" ng-style="{'top': yCropZone + 'px', 'left': 0, 'width': xCropZone + 'px', 'height': heightCropZone + 'px'}"></div>
			<div class="overlay-border" ng-style="{'top': (yCropZone - 2) + 'px', 'left': (xCropZone - 2) + 'px', 'width': widthCropZone + 'px', 'height': heightCropZone + 'px'}"></div>
		</div>
		<div class="cropme-actions" ng-show="state == 'step-2'">
			<button id="cropme-cancel" ng-click="cancel($event)">Cancel</button>
			<button id="cropme-ok" ng-click="ok($event)">Ok</button>
		</div>
		<canvas
			width="{{destinationWidth}}"
			height="{{destinationHeight}}"
			ng-style="{'width': destinationWidth + 'px', 'height': destinationHeight + 'px'}">
		</canvas>
	"""
	restrict: "E"
	scope: 
		width: "=?"
		destinationWidth: "="
		height: "=?"
		destinationHeight: "=?"
		iconClass: "=?"
		ratio: "=?"
		type: "=?"
	link: (scope, element, attributes) ->
		scope.dropText = "Drop picture here"
		scope.state = "step-1"
		draggingFn = null
		grabbedBorder = null
		heightWithImage = null
		zoom = null
		elOffset = null
		imageEl = element.find('img')[0]
		canvasEl = element.find("canvas")[0]
		ctx = canvasEl.getContext "2d"

		startCropping = (imageWidth, imageHeight) ->
			zoom = scope.width / imageWidth
			heightWithImage = imageHeight * zoom
			scope.widthCropZone = Math.round scope.destinationWidth * zoom
			scope.heightCropZone = Math.round (scope.destinationHeight || minHeight) * zoom
			scope.xCropZone = Math.round (scope.width - scope.widthCropZone) / 2
			scope.yCropZone = Math.round (scope.height - scope.heightCropZone) / 2
			$timeout -> elOffset = elementOffset imageAreaEl

		checkScopeVariables = ->
			unless scope.width
				scope.width = element[0].offsetWidth
				scope.height = element[0].offsetHeight  unless scope.ratio || scope.height
			if scope.destinationHeight
				if scope.ratio
					throw "You can't specify both destinationHeight and ratio, destinationHeight = destinationWidth * ratio"
				else
					scope.ratio = destinationHeight / destinationWidth
			else if scope.ratio
				scope.destinationHeight = scope.destinationWidth * scope.ratio
			if scope.ratio and scope.height and scope.destinationHeight > scope.height
				throw "Can't initialize cropme: destinationWidth x ratio needs to be lower than height"
			if scope.destinationWidth > scope.width
				throw "Can't initialize cropme: destinationWidth needs to be lower than width"
			if scope.ratio and not scope.height
				scope.height = scope.width * scope.ratio
			scope.type ||= "png"

		imageAreaEl = element[0].getElementsByClassName("step-2")[0]
		checkScopeVariables()
		$input = element.find("input")
		$input.bind "change", ->
			file = @files[0]
			scope.$apply -> scope.setFiles file
		$input.bind "click", (e) ->
			e.stopPropagation()
			$input.val ""
		scope.browseFiles = -> $input[0].click()
		scope.setFiles = (file) ->
			unless file.type.match /^image\//
				return scope.dropError = "Wrong file type, please select an image."
			scope.dropError = ""
			reader = new FileReader
			reader.onload = (e) ->
				imageEl.onload = ->
					width = imageEl.naturalWidth
					height = imageEl.naturalHeight
					errors = []
					if width < scope.width
						errors.push "The image you dropped has a width of #{width}, but the minimum is #{scope.width}."
					if scope.height and height < scope.height
						errors.push "The image you dropped has a height of #{height}, but the minimum is #{scope.height}."
					if scope.ratio and scope.destinationHeight > height
						errors.push "The image you dropped has a height of #{height}, but the minimum is #{scope.destinationHeight}."
					scope.$apply ->
						if errors.length
							scope.dropError = errors.join "<br/>"
						else
							$rootScope.$broadcast "cropme:loaded", width, height
							scope.state = "step-2"
							startCropping width, height
				scope.$apply -> scope.imgSrc = e.target.result
			reader.readAsDataURL(file);
							
		moveCropZone = (coords) ->
			scope.xCropZone = coords.x - elOffset.left - scope.widthCropZone / 2
			scope.yCropZone = coords.y - elOffset.top - scope.heightCropZone / 2
			checkBounds()
		moveBorders = 
			top: (coords) ->
				y = coords.y - elOffset.top
				scope.heightCropZone += scope.yCropZone - y
				scope.yCropZone = y
				checkVRatio()
				checkBounds()
			right: (coords) ->
				x = coords.x - elOffset.left
				scope.widthCropZone = x - scope.xCropZone
				checkHRatio()
				checkBounds()
			bottom: (coords) ->
				y = coords.y - elOffset.top
				scope.heightCropZone = y - scope.yCropZone
				checkVRatio()
				checkBounds()
			left: (coords) ->
				x = coords.x - elOffset.left
				scope.widthCropZone += scope.xCropZone - x
				scope.xCropZone = x
				checkHRatio()
				checkBounds()

		checkHRatio = -> scope.heightCropZone = scope.widthCropZone * scope.ratio if scope.ratio
		checkVRatio = -> scope.widthCropZone = scope.heightCropZone / scope.ratio if scope.ratio
		checkBounds = ->
			scope.xCropZone = 0 if scope.xCropZone < 0
			scope.yCropZone = 0 if scope.yCropZone < 0
			if scope.widthCropZone < scope.destinationWidth * zoom
				scope.widthCropZone = scope.destinationWidth * zoom
				checkHRatio()
			else if scope.destinationHeight and scope.heightCropZone < scope.destinationHeight * zoom
				scope.heightCropZone = scope.destinationHeight * zoom
				checkVRatio()
			if scope.xCropZone + scope.widthCropZone > scope.width
				scope.xCropZone = scope.width - scope.widthCropZone
				if scope.xCropZone < 0
					scope.widthCropZone = scope.width
					scope.xCropZone = 0
					checkHRatio()
			if scope.yCropZone + scope.heightCropZone > heightWithImage
				scope.yCropZone = heightWithImage - scope.heightCropZone
				if scope.yCropZone < 0
					scope.heightCropZone = heightWithImage
					scope.yCropZone = 0
					checkVRatio()

		isNearBorders = (coords) ->
			x = scope.xCropZone + elOffset.left
			y = scope.yCropZone + elOffset.top
			w = scope.widthCropZone
			h = scope.heightCropZone
			topLeft = { x: x, y: y }
			topRight = { x: x + w, y: y }
			bottomLeft = { x: x, y: y + h }
			bottomRight = { x: x + w, y: y + h }
			nearHSegment(coords, x, w, y, "top") or nearVSegment(coords, y, h, x + w, "right") or nearHSegment(coords, x, w, y + h, "bottom") or nearVSegment(coords, y, h, x, "left")

		nearHSegment = (coords, x, w, y, borderName) ->
			borderName if coords.x >= x and coords.x <= x + w and Math.abs(coords.y - y) <= borderSensitivity
		nearVSegment = (coords, y, h, x, borderName) ->
			borderName if coords.y >= y and coords.y <= y + h and Math.abs(coords.x - x) <= borderSensitivity

		dragIt = (coords) ->
			if draggingFn
				scope.$apply -> draggingFn(coords)

		scope.mousemove = (e) ->
			scope.colResizePointer = isNearBorders({x: e.pageX, y:e.pageY})

		$swipe.bind angular.element(element[0].getElementsByClassName('step-2')[0]),
			'start': (coords) ->
				grabbedBorder = isNearBorders coords
				if grabbedBorder
					draggingFn = moveBorders[grabbedBorder]
				else draggingFn = moveCropZone
				dragIt coords
			'move': (coords) ->
				dragIt coords
			'end': (coords) ->
				dragIt coords
				draggingFn = null

		scope.deselect = -> draggingFn = null
		scope.cancel = ($event) ->
			$event.preventDefault() if $event
			scope.dropText = "Drop files here"
			scope.dropClass = ""
			scope.state = "step-1"
		scope.ok = ($event) ->
			$event.preventDefault() if $event
			scope.croppedWidth = scope.widthCropZone / zoom
			scope.croppedHeight = scope.heightCropZone / zoom
			$timeout ->
				destinationHeight = scope.destinationHeight || scope.destinationWidth * scope.croppedHeight / scope.croppedWidth
				ctx.drawImage imageEl, scope.xCropZone / zoom, scope.yCropZone / zoom, scope.croppedWidth, scope.croppedHeight, 0, 0, scope.destinationWidth, scope.destinationHeight
				canvasEl.toBlob (blob) ->
					$rootScope.$broadcast "cropme:done", blob
				, 'image/' + scope.type
		scope.$on "cropme:cancel", scope.cancel
		scope.$on "cropme:ok", scope.ok

angular.module("cropme").directive "dropbox", (elementOffset) ->
	restrict: "E"
	link: (scope, element, attributes) ->
		offset = elementOffset element
		reset = (evt) ->
			evt.stopPropagation()
			evt.preventDefault()
			scope.$apply ->
				scope.dragOver = false
				scope.dropText = "Drop files here"
				scope.dropClass = ""
		dragEnterLeave = (evt) ->
			return if evt.x > offset.left and evt.x < offset.left + element[0].offsetWidth and evt.y > offset.top and evt.y < offset.top + element[0].offsetHeight
			reset evt
		dropbox = element[0]
		scope.dropText = "Drop files here"
		scope.dragOver = false
		dropbox.addEventListener "dragenter", dragEnterLeave, false
		dropbox.addEventListener "dragleave", dragEnterLeave, false
		dropbox.addEventListener "dragover", ((evt) ->
			evt.stopPropagation()
			evt.preventDefault()
			ok = evt.dataTransfer and evt.dataTransfer.types and evt.dataTransfer.types.indexOf("Files") >= 0
			scope.$apply ->
				scope.dragOver = true
				scope.dropText = (if ok then "Drop now" else "Only files are allowed")
				scope.dropClass = (if ok then "over" else "not-available")

		), false
		dropbox.addEventListener "drop", ((evt) ->
			reset evt

			files = evt.dataTransfer.files
			scope.$apply ->
				if files.length > 0
					for file in files
						if file.type.match /^image\//
							scope.dropText = "Loading image..."
							scope.dropClass = "loading"
							return scope.setFiles(file)
						scope.dropError = "Wrong file type, please drop at least an image."
		), false


# canvas-toBlob.js
# * A canvas.toBlob() implementation.
# * 2011-07-13
# * 
# * By Eli Grey, http://eligrey.com and Devin Samarin, https://github.com/eboyjr
# * License: X11/MIT
# *   See LICENSE.md
# 

#global self 

#jslint bitwise: true, regexp: true, confusion: true, es5: true, vars: true, white: true,
#  plusplus: true 

#! @source http://purl.eligrey.com/github/canvas-toBlob.js/blob/master/canvas-toBlob.js 
((view) ->
  "use strict"
  Uint8Array = view.Uint8Array
  HTMLCanvasElement = view.HTMLCanvasElement
  is_base64_regex = /\s*;\s*base64\s*(?:;|$)/i
  base64_ranks = undefined
  decode_base64 = (base64) ->
    len = base64.length
    buffer = new Uint8Array(len / 4 * 3 | 0)
    i = 0
    outptr = 0
    last = [0, 0]
    state = 0
    save = 0
    rank = undefined
    code = undefined
    undef = undefined
    while len--
      code = base64.charCodeAt(i++)
      rank = base64_ranks[code - 43]
      if rank isnt 255 and rank isnt undef
        last[1] = last[0]
        last[0] = code
        save = (save << 6) | rank
        state++
        if state is 4
          buffer[outptr++] = save >>> 16
          # padding character 
          buffer[outptr++] = save >>> 8  if last[1] isnt 61
          # padding character 
          buffer[outptr++] = save  if last[0] isnt 61
          state = 0
    
    # 2/3 chance there's going to be some null bytes at the end, but that
    # doesn't really matter with most image formats.
    # If it somehow matters for you, truncate the buffer up outptr.
    buffer

  base64_ranks = new Uint8Array([62, -1, -1, -1, 63, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, -1, -1, -1, 0, -1, -1, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, -1, -1, -1, -1, -1, -1, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51])  if Uint8Array
  if HTMLCanvasElement and not HTMLCanvasElement::toBlob
    HTMLCanvasElement::toBlob = (callback, type) -> #, ...args
      type = "image/png"  unless type
      if @mozGetAsFile
        callback @mozGetAsFile("canvas", type)
        return
      args = Array::slice.call(arguments, 1)
      dataURI = @toDataURL.apply(this, args)
      header_end = dataURI.indexOf(",")
      data = dataURI.substring(header_end + 1)
      is_base64 = is_base64_regex.test(dataURI.substring(0, header_end))
      blob = undefined
      if Blob.fake
        
        # no reason to decode a data: URI that's just going to become a data URI again
        blob = new Blob
        if is_base64
          blob.encoding = "base64"
        else
          blob.encoding = "URI"
        blob.data = data
        blob.size = data.length
      else if Uint8Array
        if is_base64
          blob = new Blob([decode_base64(data)],
            type: type
          )
        else
          blob = new Blob([decodeURIComponent(data)],
            type: type
          )
      callback blob
) self