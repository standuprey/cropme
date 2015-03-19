"use strict"
angular.module("cropmeDemo").controller "MainCtrl", ($scope, $timeout) ->
	$timeout ->
		$scope.src = "images/kitten.jpeg"
		$scope.width = 640
		$scope.ratio = 1
	, 100

	$scope.$on "cropme:done", (e, blob) ->
		console.log blob
