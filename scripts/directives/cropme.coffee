###*
 # @ngdoc directive
 # @name cropme
 # @requires $swipe, $window, $timeout, $rootScope, elementOffset, canvasToBlob
 # @description
 # Main directive for the cropme module, see readme.md for the different options and example
 #
###
angular.module("cropme").directive "cropme", ($swipe, $window, $timeout, $rootScope, $q, elementOffset, canvasToBlob) ->

	minHeight = 100 # if destinationHeight has not been defined, we need a default height for the crop zone
	borderSensitivity = 8 # grab area size around the borders in pixels

	template: """
		<div
			class="step-1"
			ng-show="checkScopeVariables() && state == 'step-1'"
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
			ng-style="{'width': width + 'px', cursor: colResizePointer}"
			ng-mousemove="mousemove($event)"
			ng-mouseleave="deselect()">
			<img ng-src="{{imgSrc}}" ng-style="{'width': width + 'px'}" ng-show="imgLoaded"/>
			<div class="overlay-tile" ng-style="{'top': 0, 'left': 0, 'width': xCropZone + 'px', 'height': yCropZone + 'px'}"></div>
			<div class="overlay-tile" ng-style="{'top': 0, 'left': xCropZone + 'px', 'width': widthCropZone + 'px', 'height': yCropZone + 'px'}"></div>
			<div class="overlay-tile" ng-style="{'top': 0, 'left': xCropZone + widthCropZone + 'px', 'right': 0, 'height': yCropZone + 'px'}"></div>
			<div class="overlay-tile" ng-style="{'top': yCropZone + 'px', 'left': xCropZone + widthCropZone + 'px', 'right': 0, 'height': heightCropZone + 'px'}"></div>
			<div class="overlay-tile" ng-style="{'top': yCropZone + heightCropZone + 'px', 'left': xCropZone + widthCropZone + 'px', 'right': 0, 'bottom': 0}"></div>
			<div class="overlay-tile" ng-style="{'top': yCropZone + heightCropZone + 'px', 'left': xCropZone + 'px', 'width': widthCropZone + 'px', 'bottom': 0}"></div>
			<div class="overlay-tile" ng-style="{'top': yCropZone + heightCropZone + 'px', 'left': 0, 'width': xCropZone + 'px', 'bottom': 0}"></div>
			<div class="overlay-tile" ng-style="{'top': yCropZone + 'px', 'left': 0, 'width': xCropZone + 'px', 'height': heightCropZone + 'px'}"></div>
			<div class="overlay-border" ng-style="{'top': (yCropZone - 2) + 'px', 'left': (xCropZone - 2) + 'px', 'width': (widthCropZone - 2) + 'px', 'height': (heightCropZone - 2) + 'px'}"></div>
		</div>
		<div class="cropme-actions" ng-show="state == 'step-2'">
			<button id="cropme-cancel" ng-click="cancel($event)">{{cancelLabel}}</button>
			<button id="cropme-ok" ng-click="ok($event)">{{okLabel}}</button>
		</div>
		<canvas
			width="{{destinationWidth}}"
			height="{{destinationHeight}}"
			ng-style="{'width': destinationWidth + 'px', 'height': destinationHeight + 'px'}">
		</canvas>
	"""
	restrict: "E"
	priority: 99 # it needs to run after the attributes are interpolated
	scope:
		width: "@?"
		destinationWidth: "@"
		height: "@?"
		destinationHeight: "@?"
		iconClass: "@?"
		ratio: "@?"
		type: "@?"
		src: "@?"
		sendOriginal: "@?"
		sendCropped: "@?"
		id: "@?"
		okLabel: "@?"
		cancelLabel: "@?"
	link: (scope, element, attributes) ->
		scope.dropText = "Drop picture here"
		scope.state = "step-1"
		draggingFn = null
		grabbedBorder = null
		heightWithImage = null
		zoom = null
		imageEl = element.find('img')[0]
		canvasEl = element.find("canvas")[0]
		ctx = canvasEl.getContext "2d"

		sendCropped = -> scope.sendCropped is `undefined` or scope.sendCropped is "true"
		sendOriginal = -> scope.sendOriginal is "true"
		startCropping = (imageWidth, imageHeight) ->
			zoom = scope.width / imageWidth
			heightWithImage = imageHeight * zoom
			scope.widthCropZone = Math.round scope.destinationWidth * zoom
			scope.heightCropZone = Math.round (scope.destinationHeight || minHeight) * zoom
			scope.xCropZone = Math.round (scope.width - scope.widthCropZone) / 2
			scope.yCropZone = Math.round (scope.height - scope.heightCropZone) / 2

		scope.checkScopeVariables = ->
			if scope.destinationHeight and not scope.ratio
				scope.ratio = scope.destinationHeight / scope.destinationWidth
			else if scope.ratio
				scope.destinationHeight = scope.destinationWidth * scope.ratio
			if scope.ratio and not scope.height
				scope.height = scope.width * scope.ratio
			scope.type ||= "png"
			scope.okLabel ||= "Ok"
			scope.cancelLabel ||= "Cancel"
			true

		imageAreaEl = element[0].getElementsByClassName("step-2")[0]
		elOffset = -> elementOffset imageAreaEl
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
			scope.filename = file.name
			scope.dropError = ""
			reader = new FileReader
			reader.onload = (e) ->
				scope.$apply -> loadImage e.target.result, true
			reader.readAsDataURL(file);
		loadImage = (src, base64Src = false) ->
			return unless src
			scope.state = "step-2"
			if src isnt scope.imgSrc
				scope.imgSrc = src
				scope.imgLoaded = false
				img = new Image
				img.onerror = ->
					scope.$apply ->
						scope.cancel()
						scope.dropError = "Unsupported type of image"
				img.onload = ->
					width = img.width
					height = img.height
					errors = []
					if width < scope.width
						errors.push "The image you dropped has a width of #{width}, but the minimum is #{scope.width}."
					minHeight = Math.min scope.height, scope.destinationHeight
					if height < minHeight
						errors.push "The image you dropped has a height of #{height}, but the minimum is #{minHeight}."
					scope.$apply ->
						if errors.length
							scope.cancel()
							scope.dropError = errors.join "<br/>"
						else
							scope.imgLoaded = true
							$rootScope.$broadcast "cropme:loaded", width, height
							sendImageEvent "progress"
							startCropping width, height
				img.crossOrigin = "anonymous"  unless base64Src
				img.src = src

		moveCropZone = (coords) ->
			offset = elOffset()
			scope.xCropZone = coords.x - offset.left - scope.widthCropZone / 2
			scope.yCropZone = coords.y - offset.top - scope.heightCropZone / 2
			checkBoundsAndSendProgressEvent()
		moveBorders =
			top: (coords) ->
				y = coords.y - elOffset().top
				scope.heightCropZone += scope.yCropZone - y
				scope.yCropZone = y
				checkVRatio()
				checkBoundsAndSendProgressEvent()
			right: (coords) ->
				x = coords.x - elOffset().left
				scope.widthCropZone = x - scope.xCropZone
				checkHRatio()
				checkBoundsAndSendProgressEvent()
			bottom: (coords) ->
				y = coords.y - elOffset().top
				scope.heightCropZone = y - scope.yCropZone
				checkVRatio()
				checkBoundsAndSendProgressEvent()
			left: (coords) ->
				x = coords.x - elOffset().left
				scope.widthCropZone += scope.xCropZone - x
				scope.xCropZone = x
				checkHRatio()
				checkBoundsAndSendProgressEvent()

		checkHRatio = -> scope.heightCropZone = scope.widthCropZone * scope.ratio if scope.ratio
		checkVRatio = -> scope.widthCropZone = scope.heightCropZone / scope.ratio if scope.ratio
		checkBoundsAndSendProgressEvent = ->
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
			debouncedSendImageEvent "progress"

		isNearBorders = (coords) ->
			offset = elOffset()
			x = scope.xCropZone + offset.left
			y = scope.yCropZone + offset.top
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

		getCropPromise = ->
			deferred = $q.defer()
			if sendCropped()
				ctx.drawImage imageEl, scope.xCropZone / zoom, scope.yCropZone / zoom, scope.croppedWidth, scope.croppedHeight, 0, 0, scope.destinationWidth, scope.destinationHeight
				canvasToBlob canvasEl, ((blob) -> deferred.resolve(blob)), "image/#{scope.type}"
			else
				deferred.resolve()
			deferred.promise

		getOriginalPromise = ->
			deferred = $q.defer()
			if sendOriginal()
				originalCanvas = document.createElement "canvas"
				originalContext = originalCanvas.getContext "2d"
				originalCanvas.width = imageEl.naturalWidth
				originalCanvas.height = imageEl.naturalHeight
				originalContext.drawImage imageEl, 0, 0
				canvasToBlob originalCanvas, ((blob) -> deferred.resolve(blob)), "image/#{scope.type}"
			else
				deferred.resolve()
			deferred.promise

		sendImageEvent = (eventName) ->
			console.log eventName
			scope.croppedWidth = scope.widthCropZone / zoom
			scope.croppedHeight = scope.heightCropZone / zoom
			$q.all([getCropPromise(), getOriginalPromise()]).then (blobArray) ->
				result =
					x: scope.xCropZone / zoom
					y: scope.yCropZone / zoom
					height: scope.croppedHeight
					width: scope.croppedWidth
					destinationHeight: scope.destinationHeight
					destinationWidth: scope.destinationWidth
					filename: scope.filename
				result.croppedImage = blobArray[0]  if blobArray[0]
				result.originalImage = blobArray[1]  if blobArray[1]
				$rootScope.$broadcast "cropme:#{eventName}", result, "image/#{scope.type}", scope.id
		debounce = (func, wait, immediate) ->
			timeout = undefined
			->
				context = this
				args = arguments

				later = ->
					timeout = null
					if !immediate
						func.apply context, args
					return

				callNow = immediate and !timeout
				clearTimeout timeout
				timeout = setTimeout(later, wait)
				if callNow
					func.apply context, args
				return

		scope.mousemove = (e) ->
			scope.colResizePointer = switch isNearBorders({x: e.pageX - window.scrollX, y:(e.pageY - window.scrollY)})
				when 'top' then 'ne-resize'
				when 'right', 'bottom' then 'se-resize'
				when 'left' then 'sw-resize'
				else 'move'

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
			delete scope.imgSrc
			delete scope.filename

		scope.ok = ($event) ->
			$event.preventDefault() if $event
			sendImageEvent "done"

		scope.$on "cropme:cancel", scope.cancel
		scope.$on "cropme:ok", scope.ok
		scope.$watch "src", ->
			if scope.src
				scope.filename = scope.src
				if scope.src.indexOf("data:image") is 0
					loadImage(scope.src, true)
				else
					delimit = if scope.src.match(/\?/) then "&" else "?"
					loadImage "#{scope.src}#{delimit}crossOrigin"
		debouncedSendImageEvent = debounce sendImageEvent, 300
