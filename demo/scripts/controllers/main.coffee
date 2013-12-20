"use strict"
angular.module("cropmeDemo").controller "MainCtrl", ($scope) ->
	$scope.$on "cropme", (e, blob) ->
		console.log blob
