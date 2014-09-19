module.exports =
	options:
		sassDir: "styles"
		cssDir: "."
		raw: "http_images_path = \"images/\"\ngenerated_images_dir = \".tmp/images\"\nhttp_generated_images_path = \"../images/\""
		
		# This doesn't work with relative paths.
		relativeAssets: false

	dist: {}
