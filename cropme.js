(function() {
  angular.module("cropme", ["ngSanitize"]).directive("cropme", [
    "$window", "$timeout", "$rootScope", function($window, $timeout, $rootScope) {
      var borderSensitivity, checkScopeVariables, minHeight;
      minHeight = 100;
      borderSensitivity = 8;
      checkScopeVariables = function(scope) {
        if (scope.destinationHeight) {
          if (scope.ratio) {
            throw "You can't specify both destinationHeight and ratio, destinationHeight = destinationWidth * ratio";
          } else {
            scope.ratio = destinationHeight / destinationWidth;
          }
        } else if (scope.ratio) {
          scope.destinationHeight = scope.destinationWidth * scope.ratio;
        }
        if (scope.ratio && scope.height && scope.destinationHeight > scope.height) {
          throw "Can't initialize cropme: destinationWidth x ratio needs to be lower than height";
        }
        if (scope.destinationWidth > scope.width) {
          throw "Can't initialize cropme: destinationWidth needs to be lower than width";
        }
        if (scope.ratio && !scope.height) {
          scope.height = scope.destinationHeight;
        }
        return scope.type || (scope.type = "png");
      };
      return {
        template: "<div\n	class=\"step-1\"\n	ng-show=\"state == 'step-1'\"\n	ng-style=\"{'width': width + 'px', 'height': height + 'px'}\">\n	<dropbox ng-class=\"dropClass\"></dropbox>\n	<div class=\"cropme-error\" ng-bind-html=\"dropError\"></div>\n	<div class=\"cropme-file-input\">\n		<input type=\"file\"/>\n		<div\n			class=\"cropme-button\"\n			ng-click=\"browseFiles()\">\n				Browse picture\n		</div>\n		<div class=\"cropme-or\">or</div>\n		<div class=\"cropme-label\">{{dropText}}</div>\n	</div>\n</div>\n<div\n	class=\"step-2\"\n	ng-show=\"state == 'step-2'\"\n	ng-style=\"{'width': width + 'px', 'height': height + 'px'}\"\n	ng-mousemove=\"mousemove($event)\"\n	ng-mousedown=\"mousedown($event)\"\n	ng-mouseup=\"mouseup($event)\"\n	ng-mouseleave=\"deselect()\"\n	ng-class=\"{'overflow-hidden': autocrop, 'col-resize': colResizePointer}\">\n	<img ng-src=\"{{imgSrc}}\" ng-style=\"{'width': width + 'px'}\"/>\n	<div class=\"overlay-tile\" ng-style=\"{'top': 0, 'left': 0, 'width': xCropZone + 'px', 'height': yCropZone + 'px'}\"></div>\n	<div class=\"overlay-tile\" ng-style=\"{'top': 0, 'left': xCropZone + 'px', 'width': widthCropZone + 'px', 'height': yCropZone + 'px'}\"></div>\n	<div class=\"overlay-tile\" ng-style=\"{'top': 0, 'left': xCropZone + widthCropZone + 'px', 'right': 0, 'height': yCropZone + 'px'}\"></div>\n	<div class=\"overlay-tile\" ng-style=\"{'top': yCropZone + 'px', 'left': xCropZone + widthCropZone + 'px', 'right': 0, 'height': heightCropZone + 'px'}\"></div>\n	<div class=\"overlay-tile\" ng-style=\"{'top': yCropZone + heightCropZone + 'px', 'left': xCropZone + widthCropZone + 'px', 'right': 0, 'bottom': 0}\"></div>\n	<div class=\"overlay-tile\" ng-style=\"{'top': yCropZone + heightCropZone + 'px', 'left': xCropZone + 'px', 'width': widthCropZone + 'px', 'bottom': 0}\"></div>\n	<div class=\"overlay-tile\" ng-style=\"{'top': yCropZone + heightCropZone + 'px', 'left': 0, 'width': xCropZone + 'px', 'bottom': 0}\"></div>\n	<div class=\"overlay-tile\" ng-style=\"{'top': yCropZone + 'px', 'left': 0, 'width': xCropZone + 'px', 'height': heightCropZone + 'px'}\"></div>\n	<div class=\"overlay-border\" ng-style=\"{'top': (yCropZone - 2) + 'px', 'left': (xCropZone - 2) + 'px', 'width': widthCropZone + 'px', 'height': heightCropZone + 'px'}\"></div>\n</div>\n<div class=\"cropme-actions\" ng-show=\"state == 'step-2'\">\n	<button ng-click=\"cancel()\">Cancel</button>\n	<button ng-click=\"ok()\">Ok</button>\n</div>\n<canvas\n	width=\"{{croppedWidth}}\"\n	height=\"{{croppedHeight}}\"\n	ng-style=\"{'width': destinationWidth + 'px', 'height': destinationHeight + 'px'}\">\n</canvas>",
        restrict: "E",
        scope: {
          width: "=",
          destinationWidth: "=",
          height: "=?",
          destinationHeight: "=?",
          autocrop: "=?",
          ratio: "=?",
          type: "=?"
        },
        link: function(scope, element, attributes) {
          var $input, canvasEl, checkBounds, checkHRatio, checkVRatio, ctx, draggingFn, grabbedBorder, heightWithImage, imageAreaEl, imageEl, isNearBorders, moveBorders, moveCropZone, nearHSegment, nearVSegment, startCropping, zoom;
          scope.dropText = "Drop picture here";
          scope.state = "step-1";
          draggingFn = null;
          grabbedBorder = null;
          heightWithImage = null;
          zoom = null;
          imageEl = element.find('img')[0];
          canvasEl = element.find("canvas")[0];
          ctx = canvasEl.getContext("2d");
          startCropping = function(imageWidth, imageHeight) {
            zoom = scope.width / imageWidth;
            heightWithImage = scope.autocrop && scope.height ? scope.height : imageHeight * zoom;
            scope.widthCropZone = Math.round(scope.destinationWidth * zoom);
            scope.heightCropZone = Math.round((scope.destinationHeight || minHeight) * zoom);
            scope.xCropZone = Math.round((scope.width - scope.widthCropZone) / 2);
            return scope.yCropZone = Math.round((scope.height - scope.heightCropZone) / 2);
          };
          imageAreaEl = element[0].getElementsByClassName("step-2")[0];
          checkScopeVariables(scope);
          $input = element.find("input");
          $input.bind("change", function() {
            var file;
            file = this.files[0];
            return scope.$apply(function() {
              return scope.setFiles(file);
            });
          });
          $input.bind("click", function(e) {
            e.stopPropagation();
            return $input.val("");
          });
          scope.browseFiles = function() {
            return $input[0].click();
          };
          scope.setFiles = function(file) {
            var reader;
            if (!file.type.match(/^image\//)) {
              return scope.dropError = "Wrong file type, please select an image.";
            }
            scope.dropError = "";
            reader = new FileReader;
            reader.onload = function(e) {
              imageEl.onload = function() {
                var errors, height, width;
                width = imageEl.naturalWidth;
                height = imageEl.naturalHeight;
                errors = [];
                if (width < scope.width) {
                  errors.push("The image you dropped has a width of " + width + ", but the minimum is " + scope.width + ".");
                }
                if (scope.height && height < scope.height) {
                  errors.push("The image you dropped has a height of " + height + ", but the minimum is " + scope.height + ".");
                }
                if (scope.ratio && scope.destinationHeight > height) {
                  errors.push("The image you dropped has a height of " + height + ", but the minimum is " + scope.destinationHeight + ".");
                }
                return scope.$apply(function() {
                  if (errors.length) {
                    return scope.dropError = errors.join("<br/>");
                  } else {
                    scope.state = "step-2";
                    return startCropping(width, height);
                  }
                });
              };
              return scope.$apply(function() {
                return scope.imgSrc = e.target.result;
              });
            };
            return reader.readAsDataURL(file);
          };
          moveCropZone = function(coords) {
            scope.xCropZone = coords.x - imageAreaEl.offsetLeft - scope.widthCropZone / 2;
            scope.yCropZone = coords.y - imageAreaEl.offsetTop - scope.heightCropZone / 2;
            return checkBounds();
          };
          moveBorders = {
            top: function(coords) {
              var y;
              y = coords.y - imageAreaEl.offsetTop;
              scope.heightCropZone += scope.yCropZone - y;
              scope.yCropZone = y;
              checkVRatio();
              return checkBounds();
            },
            right: function(coords) {
              var x;
              x = coords.x - imageAreaEl.offsetLeft;
              scope.widthCropZone = x - scope.xCropZone;
              checkHRatio();
              return checkBounds();
            },
            bottom: function(coords) {
              var y;
              y = coords.y - imageAreaEl.offsetTop;
              scope.heightCropZone = y - scope.yCropZone;
              checkVRatio();
              return checkBounds();
            },
            left: function(coords) {
              var x;
              x = coords.x - imageAreaEl.offsetLeft;
              scope.widthCropZone += scope.xCropZone - x;
              scope.xCropZone = x;
              checkHRatio();
              return checkBounds();
            }
          };
          checkHRatio = function() {
            if (scope.ratio) {
              return scope.heightCropZone = scope.widthCropZone * scope.ratio;
            }
          };
          checkVRatio = function() {
            if (scope.ratio) {
              return scope.widthCropZone = scope.heightCropZone / scope.ratio;
            }
          };
          checkBounds = function() {
            if (scope.xCropZone < 0) {
              scope.xCropZone = 0;
            }
            if (scope.yCropZone < 0) {
              scope.yCropZone = 0;
            }
            if (scope.widthCropZone < scope.destinationWidth * zoom) {
              scope.widthCropZone = scope.destinationWidth * zoom;
              checkHRatio();
            } else if (scope.destinationHeight && scope.heightCropZone < scope.destinationHeight * zoom) {
              scope.heightCropZone = scope.destinationHeight * zoom;
              checkVRatio();
            }
            if (scope.xCropZone + scope.widthCropZone > scope.width) {
              scope.xCropZone = scope.width - scope.widthCropZone;
              if (scope.xCropZone < 0) {
                scope.widthCropZone = scope.width;
                scope.xCropZone = 0;
                checkHRatio();
              }
            }
            if (scope.yCropZone + scope.heightCropZone > heightWithImage) {
              scope.yCropZone = heightWithImage - scope.heightCropZone;
              if (scope.yCropZone < 0) {
                scope.heightCropZone = heightWithImage;
                scope.yCropZone = 0;
                return checkVRatio();
              }
            }
          };
          isNearBorders = function(coords) {
            var bottomLeft, bottomRight, h, topLeft, topRight, w, x, y;
            x = scope.xCropZone + imageAreaEl.offsetLeft;
            y = scope.yCropZone + imageAreaEl.offsetTop;
            w = scope.widthCropZone;
            h = scope.heightCropZone;
            topLeft = {
              x: x,
              y: y
            };
            topRight = {
              x: x + w,
              y: y
            };
            bottomLeft = {
              x: x,
              y: y + h
            };
            bottomRight = {
              x: x + w,
              y: y + h
            };
            return nearHSegment(coords, x, w, y, "top") || nearVSegment(coords, y, h, x + w, "right") || nearHSegment(coords, x, w, y + h, "bottom") || nearVSegment(coords, y, h, x, "left");
          };
          nearHSegment = function(coords, x, w, y, borderName) {
            if (coords.x >= x && coords.x <= x + w && Math.abs(coords.y - y) <= borderSensitivity) {
              return borderName;
            }
          };
          nearVSegment = function(coords, y, h, x, borderName) {
            if (coords.y >= y && coords.y <= y + h && Math.abs(coords.x - x) <= borderSensitivity) {
              return borderName;
            }
          };
          scope.mousedown = function(e) {
            grabbedBorder = isNearBorders(e);
            if (grabbedBorder) {
              draggingFn = moveBorders[grabbedBorder];
            } else {
              draggingFn = moveCropZone;
            }
            return draggingFn(e);
          };
          scope.mouseup = function(e) {
            draggingFn(e);
            return draggingFn = null;
          };
          scope.mousemove = function(e) {
            if (draggingFn) {
              draggingFn(e);
            }
            return scope.colResizePointer = isNearBorders(e);
          };
          scope.deselect = function() {
            return draggingFn = null;
          };
          scope.cancel = function() {
            scope.dropText = "Drop files here";
            scope.dropClass = "";
            return scope.state = "step-1";
          };
          return scope.ok = function() {
            scope.croppedWidth = scope.widthCropZone / zoom;
            scope.croppedHeight = scope.heightCropZone / zoom;
            return $timeout(function() {
              var base64ImageData, blob, raw;
              ctx.drawImage(imageEl, scope.xCropZone / zoom, scope.yCropZone / zoom, scope.croppedWidth, scope.croppedHeight, 0, 0, scope.croppedWidth, scope.croppedHeight);
              base64ImageData = canvasEl.toDataURL('image/' + scope.type).replace("data:image/" + scope.type + ";base64,", "");
              raw = $window.atob(base64ImageData);
              blob = new Blob([raw], {
                type: "image/" + scope.type
              });
              return $rootScope.$broadcast("cropme", blob);
            });
          };
        }
      };
    }
  ]);

  angular.module("cropme").directive("dropbox", function() {
    return {
      restrict: "E",
      link: function(scope, element, attributes) {
        var dragEnterLeave, dropbox;
        dragEnterLeave = function(evt) {
          evt.stopPropagation();
          evt.preventDefault();
          return scope.$apply(function() {
            scope.dropText = "Drop files here";
            return scope.dropClass = "";
          });
        };
        dropbox = element[0];
        scope.dropText = "Drop files here";
        dropbox.addEventListener("dragenter", dragEnterLeave, false);
        dropbox.addEventListener("dragleave", dragEnterLeave, false);
        dropbox.addEventListener("dragover", (function(evt) {
          var ok;
          evt.stopPropagation();
          evt.preventDefault();
          ok = evt.dataTransfer && evt.dataTransfer.types && evt.dataTransfer.types.indexOf("Files") >= 0;
          return scope.$apply(function() {
            scope.dropText = (ok ? "Drop now" : "Only files are allowed");
            return scope.dropClass = (ok ? "over" : "not-available");
          });
        }), false);
        return dropbox.addEventListener("drop", (function(evt) {
          var files;
          evt.stopPropagation();
          evt.preventDefault();
          scope.$apply(function() {
            scope.dropText = "Drop files here";
            return scope.dropClass = "";
          });
          files = evt.dataTransfer.files;
          return scope.$apply(function() {
            var file, _i, _len;
            if (files.length > 0) {
              for (_i = 0, _len = files.length; _i < _len; _i++) {
                file = files[_i];
                if (file.type.match(/^image\//)) {
                  scope.dropText = "Loading image...";
                  scope.dropClass = "loading";
                  return scope.setFiles(file);
                }
                scope.dropError = "Wrong file type, please drop at least an image.";
              }
            }
          });
        }), false);
      }
    };
  });

}).call(this);
