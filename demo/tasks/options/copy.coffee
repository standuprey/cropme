module.exports =
	dist:
		files: [
			{
				expand: true
				dot: true
				cwd: "app"
				dest: "dist"
				src: [
					"*.{ico,png,txt}"
					"*.html"
					"views/{,*/}*.html"
					"styles/*.css"
					"images/*.*"
				]
			}
		]
