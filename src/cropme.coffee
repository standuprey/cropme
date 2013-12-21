angular.module("cropme", ["ngSanitize"]).directive "cropme", ["$window", "$timeout", "$rootScope", ($window, $timeout, $rootScope) ->

	minHeight = 100 # if destinationHeight has not been defined, we need a default height for the crop zone
	borderSensitivity = 8 # grab area size around the borders in pixels

	checkScopeVariables = (scope) ->
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
			scope.height = scope.destinationHeight
		scope.type ||= "png"

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
					ng-click="browseFiles()">
						Browse picture
				</div>
				<div class="cropme-or">or</div>
				<div class="cropme-label">{{dropText}}</div>
			</div>
		</div>
		<div
			class="step-2"
			ng-show="state == 'step-2'"
			ng-style="{'width': width + 'px', 'height': height + 'px'}"
			ng-mousemove="mousemove($event)"
			ng-mousedown="mousedown($event)"
			ng-mouseup="mouseup($event)"
			ng-mouseleave="deselect()"
			ng-class="{'overflow-hidden': autocrop, 'col-resize': colResizePointer}">
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
			<button ng-click="cancel()">Cancel</button>
			<button ng-click="ok()">Ok</button>
		</div>
		<canvas
			width="{{croppedWidth}}"
			height="{{croppedHeight}}"
			ng-style="{'width': destinationWidth + 'px', 'height': destinationHeight + 'px'}">
		</canvas>
	"""
	restrict: "E"
	scope: 
		width: "="
		destinationWidth: "="
		height: "=?"
		destinationHeight: "=?"
		autocrop: "=?"
		ratio: "=?"
		type: "=?"
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

		startCropping = (imageWidth, imageHeight) ->
			zoom = scope.width / imageWidth
			heightWithImage = if scope.autocrop and scope.height then scope.height else imageHeight * zoom
			scope.widthCropZone = Math.round scope.destinationWidth * zoom
			scope.heightCropZone = Math.round (scope.destinationHeight || minHeight) * zoom
			scope.xCropZone = Math.round (scope.width - scope.widthCropZone) / 2
			scope.yCropZone = Math.round (scope.height - scope.heightCropZone) / 2

		imageAreaEl = element[0].getElementsByClassName("step-2")[0]
		checkScopeVariables scope
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
							scope.state = "step-2"
							startCropping width, height
				scope.$apply -> scope.imgSrc = e.target.result
			reader.readAsDataURL(file);
							
		moveCropZone = (coords) ->
			scope.xCropZone = coords.x - imageAreaEl.offsetLeft - scope.widthCropZone / 2
			scope.yCropZone = coords.y - imageAreaEl.offsetTop - scope.heightCropZone / 2
			checkBounds()
		moveBorders = 
			top: (coords) ->
				y = coords.y - imageAreaEl.offsetTop
				scope.heightCropZone += scope.yCropZone - y
				scope.yCropZone = y
				checkVRatio()
				checkBounds()
			right: (coords) ->
				x = coords.x - imageAreaEl.offsetLeft
				scope.widthCropZone = x - scope.xCropZone
				checkHRatio()
				checkBounds()
			bottom: (coords) ->
				y = coords.y - imageAreaEl.offsetTop
				scope.heightCropZone = y - scope.yCropZone
				checkVRatio()
				checkBounds()
			left: (coords) ->
				x = coords.x - imageAreaEl.offsetLeft
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
			x = scope.xCropZone + imageAreaEl.offsetLeft
			y = scope.yCropZone + imageAreaEl.offsetTop
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

		scope.mousedown = (e) ->
			grabbedBorder = isNearBorders(e)
			if grabbedBorder
				draggingFn = moveBorders[grabbedBorder]
			else draggingFn = moveCropZone
			draggingFn(e)
		scope.mouseup = (e) -> 
			draggingFn(e)
			draggingFn = null
		scope.mousemove = (e) ->
			draggingFn(e) if draggingFn
			scope.colResizePointer = isNearBorders(e)
		scope.deselect = -> draggingFn = null
		scope.cancel = ->
			scope.dropText = "Drop files here"
			scope.dropClass = ""
			scope.state = "step-1"
		scope.ok = ->
			scope.croppedWidth = scope.widthCropZone / zoom
			scope.croppedHeight = scope.heightCropZone / zoom
			$timeout ->
				ctx.drawImage imageEl, scope.xCropZone / zoom, scope.yCropZone / zoom, scope.croppedWidth, scope.croppedHeight, 0, 0, scope.croppedWidth, scope.croppedHeight
				base64ImageData = canvasEl.toDataURL('image/' + scope.type).replace("data:image/#{scope.type};base64,", "")
				raw = $window.atob base64ImageData
				blob = new Blob [raw], {type: "image/#{scope.type}"}
				$rootScope.$broadcast "cropme", blob
]

angular.module("cropme").directive "dropbox", ->
	restrict: "E"
	link: (scope, element, attributes) ->
		dragEnterLeave = (evt) ->
			evt.stopPropagation()
			evt.preventDefault()
			scope.$apply ->
				scope.dropText = "Drop files here"
				scope.dropClass = ""
		dropbox = element[0]
		scope.dropText = "Drop files here"
		dropbox.addEventListener "dragenter", dragEnterLeave, false
		dropbox.addEventListener "dragleave", dragEnterLeave, false
		dropbox.addEventListener "dragover", ((evt) ->
			evt.stopPropagation()
			evt.preventDefault()
			ok = evt.dataTransfer and evt.dataTransfer.types and evt.dataTransfer.types.indexOf("Files") >= 0
			scope.$apply ->
				scope.dropText = (if ok then "Drop now" else "Only files are allowed")
				scope.dropClass = (if ok then "over" else "not-available")

		), false
		dropbox.addEventListener "drop", ((evt) ->
			evt.stopPropagation()
			evt.preventDefault()
			scope.$apply ->
				scope.dropText = "Drop files here"
				scope.dropClass = ""

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
