"use strict"
angular.module("cropmeDemo").controller "MainCtrl", ($scope) ->
	$scope.$on "cropme:upload", (e, blob) ->
		console.log blob
