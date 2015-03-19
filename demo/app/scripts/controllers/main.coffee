"use strict"
angular.module("cropmeDemo").controller "MainCtrl", ($scope, $timeout, $sce) ->
	$timeout ->
		$scope.src = $sce.trustAsResourceUrl "http://placekitten.com/640/600"
		$scope.width = 640
		$scope.ratio = 1
	, 100

	$scope.$on "cropme:done", (e, blob) ->
		console.log blob
