angular.module("cropme", []).directive "cropme", ->
	template: """
	<ul>
		<li>Height: {{height}}</li>
		<li>Width: {{width}}</li>
		<li>Ratio: {{ratio}}</li>
		<li>Destination width: {{destinationWidth}}</li>
	</ul>	
	"""
	restrict: "E"
	scope: 
		width: "="
		height: "="
		destinationWidth: "="
		ratio: "=?"
	link: (scope, element, attributes) ->
