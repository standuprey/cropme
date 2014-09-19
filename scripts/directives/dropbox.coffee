###*
 # @ngdoc directive
 # @name dropbox
 # @requires elementOffset
 # @description
 # Simple directive to manage drag and drop of a file in an element
 #
###
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
