(function() {
  angular.module("cropme", []).directive("cropme", function() {
    return {
      templateUrl: "coprmeTemplate.html",
      restrict: "E",
      scope: {
        width: "=",
        height: "=",
        destinationMinWidth: "=",
        ratio: "=?"
      },
      link: function(scope, element, attributes) {}
    };
  });

}).call(this);
