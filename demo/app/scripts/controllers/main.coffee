"use strict"
angular.module("cropmeDemo").controller "MainCtrl", ($scope) ->
	$scope.$on "cropme:done", (e, blob) ->
		console.log blob
