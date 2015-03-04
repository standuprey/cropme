'use strict'

describe 'Service: canvasToBlob', ->

	beforeEach module 'cropme'

	it 'should create a blob with the french flag in it', inject (canvasToBlob) ->
		# upload the french flag
		uploader = (blob) -> expect(blob.size).toBe 1107
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

