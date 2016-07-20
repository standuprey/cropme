"use strict"
angular.module("cropmeDemo").controller "MainCtrl", ($scope, $timeout, $sce) ->
	$timeout ->
		$scope.src = $sce.trustAsResourceUrl "images/balloons.jpg"
	, 100

	$scope.$on "cropme:done", (e, blob, type, id) ->
		console.log blob, type, id
