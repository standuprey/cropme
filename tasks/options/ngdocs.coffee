appName = require('../../bower.json').name

module.exports =
  options:
    navTemplate: "tasks/templates/ngdocs.html"

  api:
    src: ["#{appName}.js"]
    title: appName
