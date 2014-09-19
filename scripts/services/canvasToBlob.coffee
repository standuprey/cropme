"use strict"

###*
 # @ngdoc service
 # @name canvasToBlob
 # @requires -
 # @description
 # Service based on canvas-toBlob.js By Eli Grey, http://eligrey.com and Devin Samarin, https://github.com/eboyjr
 # Transform a html canvas into a blob that can then be uploaded as a file
 #
 # @example

```js
angular.module("cropme").controller "myController", (canvasToBlob) ->
	# upload the french flag
	uploader = (blob) ->
		url = "http://my-awesome-server.com"
		xhr = new XMLHttpRequest
		xhr.setRequestHeader "Content-Type", blob.type
		xhr.onreadystatechange = (e) ->
			if @readyState is 4 and @status is 200
				console.log "done"
			else console.log "failed"  if @readyState is 4 and @status isnt 200
		xhr.open "POST", url, true
		xhr.send blob
	canvas = document.createElement "canvas"
	canvas.height = 100
	canvas.width = 300
	ctx = canvas.getContext "2d"
	ctx.fillStyle = "#0000FF"
	ctx.fillRect 0, 0, 100, 100
	ctx.fillStyle = "#FFFFFF"
	ctx.fillRect 100, 0, 200, 100
	ctx.fillStyle = "#FF0000"
	ctx.fillRect 200, 0, 300, 100
	canvasToBlob canvas, uploader, "image/png"
```
###
angular.module("cropme").service "canvasToBlob", ->
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

	base64_ranks = new Uint8Array [62, -1, -1, -1, 63, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, -1, -1, -1, 0, -1, -1, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, -1, -1, -1, -1, -1, -1, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51]

	(canvas, callback, type) ->
		type = "image/png"  unless type
		if canvas.mozGetAsFile
			callback canvas.mozGetAsFile("canvas", type)
			return
		args = Array::slice.call(arguments, 1)
		dataURI = canvas.toDataURL type
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
