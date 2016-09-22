
/**
  * @ngdoc overview
  * @name cropme
  * @requires ngSanitize, ngTouch, superswipe
  * @description
  * Drag and drop or select an image, crop it and get the blob, that you can use to upload wherever and however you want
  *
 */

(function() {
  angular.module("cropme", ["ngSanitize", "ngTouch", "superswipe"]);

}).call(this);
;
/**
  * @ngdoc directive
  * @name cropme
  * @requires superswipe, $window, $timeout, $rootScope, elementOffset, canvasToBlob
  * @description
  * Main directive for the cropme module, see readme.md for the different options and example
  *
 */

(function() {
  angular.module("cropme").directive("cropme", ["superswipe", "$window", "$timeout", "$rootScope", "$q", "elementOffset", "canvasToBlob", function(superswipe, $window, $timeout, $rootScope, $q, elementOffset, canvasToBlob) {
    var borderSensitivity, minHeight;
    minHeight = 100;
    borderSensitivity = 8;
    return {
      template: "<div\n	class=\"step-1\"\n	ng-show=\"checkScopeVariables() && state == 'step-1'\"\n	ng-click=\"browseFiles()\"\n	ng-style=\"{'width': width + 'px', 'height': height + 'px'}\">\n	<dropbox ng-class=\"dropClass\"></dropbox>\n	<div class=\"cropme-error\" ng-bind-html=\"dropError\"></div>\n	<div class=\"cropme-file-input\">\n		<input type=\"file\"/>\n		<div\n			class=\"cropme-button\"\n			ng-class=\"{deactivated: dragOver, 'cropme-button-decorated': !isHandheld}\">\n				{{browseLabel}}\n		</div>\n		<div class=\"cropme-or\" ng-hide=\"isHandheld\">{{orLabel}}</div>\n		<div class=\"cropme-label\" ng-hide=\"isHandheld\" ng-class=\"iconClass\">{{dropLabel}}</div>\n	</div>\n</div>\n<div\n	class=\"step-2\"\n	ng-show=\"state == 'step-2'\"\n	ng-style=\"{'width': width + 'px', cursor: colResizePointer}\"\n	ng-mousemove=\"mousemove($event)\"\n	ng-mouseleave=\"deselect()\">\n	<img crossOrigin=\"Anonymous\" ng-src=\"{{imgSrc}}\" ng-style=\"{'width': width ? width + 'px' : 'auto', 'height': height ? height + 'px' : 'auto'}\" ng-show=\"imgLoaded\"/>\n	<div class=\"overlay-tile\" ng-style=\"{'top': 0, 'left': 0, 'width': xCropZone + 'px', 'height': yCropZone + 'px'}\"></div>\n	<div class=\"overlay-tile\" ng-style=\"{'top': 0, 'left': xCropZone + 'px', 'width': widthCropZone + 'px', 'height': yCropZone + 'px'}\"></div>\n	<div class=\"overlay-tile\" ng-style=\"{'top': 0, 'left': xCropZone + widthCropZone + 'px', 'right': 0, 'height': yCropZone + 'px'}\"></div>\n	<div class=\"overlay-tile\" ng-style=\"{'top': yCropZone + 'px', 'left': xCropZone + widthCropZone + 'px', 'right': 0, 'height': heightCropZone + 'px'}\"></div>\n	<div class=\"overlay-tile\" ng-style=\"{'top': yCropZone + heightCropZone + 'px', 'left': xCropZone + widthCropZone + 'px', 'right': 0, 'bottom': 0}\"></div>\n	<div class=\"overlay-tile\" ng-style=\"{'top': yCropZone + heightCropZone + 'px', 'left': xCropZone + 'px', 'width': widthCropZone + 'px', 'bottom': 0}\"></div>\n	<div class=\"overlay-tile\" ng-style=\"{'top': yCropZone + heightCropZone + 'px', 'left': 0, 'width': xCropZone + 'px', 'bottom': 0}\"></div>\n	<div class=\"overlay-tile\" ng-style=\"{'top': yCropZone + 'px', 'left': 0, 'width': xCropZone + 'px', 'height': heightCropZone + 'px'}\"></div>\n	<div class=\"overlay-border\" ng-style=\"{'top': yCropZone + 'px', 'left': xCropZone + 'px', 'width': widthCropZone + 'px', 'height': heightCropZone + 'px'}\"></div>\n</div>\n<div class=\"cropme-actions\" ng-show=\"state == 'step-2'\">\n	<button id=\"cropme-cancel\" ng-click=\"cancel($event)\">{{cancelLabel}}</button>\n	<button id=\"cropme-ok\" ng-click=\"ok($event)\">{{okLabel}}</button>\n</div>\n<canvas\n	width=\"{{destinationWidth}}\"\n	height=\"{{destinationHeight}}\"\n	ng-style=\"{'width': destinationWidth + 'px', 'height': destinationHeight + 'px'}\">\n</canvas>",
      restrict: "E",
      priority: 99,
      scope: {
        width: "@?",
        destinationWidth: "@",
        height: "@?",
        destinationHeight: "@?",
        iconClass: "@?",
        ratio: "@?",
        type: "@?",
        src: "@?",
        sendOriginal: "@?",
        sendCropped: "@?",
        id: "@?",
        okLabel: "@?",
        cancelLabel: "@?",
        dropLabel: "@?",
        browseLabel: "@?",
        orLabel: "@?"
      },
      link: function(scope, element, attributes) {
        var $input, addPictureFailure, addTypeAndLoadImage, canvasEl, checkBoundsAndSendProgressEvent, checkHRatio, checkVRatio, ctx, debounce, debouncedSendImageEvent, dragIt, draggingFn, elOffset, getCropPromise, getOriginalPromise, grabbedBorder, heightWithImage, imageAreaEl, imageEl, isNearBorders, loadImage, moveBorders, moveCropZone, nearHSegment, nearVSegment, roundBounds, sendCropped, sendImageEvent, sendOriginal, startCropping, zoom;
        scope.type || (scope.type = "png");
        scope.okLabel || (scope.okLabel = "Ok");
        scope.cancelLabel || (scope.cancelLabel = "Cancel");
        scope.dropLabel || (scope.dropLabel = "Drop picture here");
        scope.browseLabel || (scope.browseLabel = "Browse picture");
        scope.orLabel || (scope.orLabel = "or");
        scope.state = "step-1";
        scope.isHandheld = /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent);
        draggingFn = null;
        grabbedBorder = null;
        heightWithImage = null;
        zoom = null;
        imageEl = element.find('img')[0];
        canvasEl = element.find("canvas")[0];
        ctx = canvasEl.getContext("2d");
        sendCropped = function() {
          return scope.sendCropped === undefined || scope.sendCropped === "true";
        };
        sendOriginal = function() {
          return scope.sendOriginal === "true";
        };
        startCropping = function(imageWidth, imageHeight) {
          zoom = scope.width / imageWidth;
          heightWithImage = imageHeight * zoom;
          if (scope.destinationWidth / scope.destinationHeight > scope.width / heightWithImage) {
            scope.widthCropZone = scope.width;
            scope.heightCropZone = Math.round(scope.width * scope.destinationHeight / scope.destinationWidth);
            scope.xCropZone = 0;
            return scope.yCropZone = Math.round((heightWithImage - scope.heightCropZone) / 2);
          } else {
            scope.widthCropZone = Math.round(heightWithImage * scope.destinationWidth / scope.destinationHeight);
            scope.heightCropZone = heightWithImage;
            scope.xCropZone = Math.round((scope.width - scope.widthCropZone) / 2);
            return scope.yCropZone = 0;
          }
        };
        scope.checkScopeVariables = function() {
          if (scope.destinationHeight) {
            scope.destinationHeight = parseInt(scope.destinationHeight, 10);
          }
          if (scope.destinationWidth) {
            scope.destinationWidth = parseInt(scope.destinationWidth, 10);
          }
          if (scope.height != null) {
            scope.height = parseInt(scope.height, 10);
          }
          if (scope.width != null) {
            scope.width = parseInt(scope.width, 10);
          } else if (!scope.height) {
            scope.width = parseInt(window.getComputedStyle(element.parent()[0]).getPropertyValue('width'), 10);
          }
          if ((scope.height == null) && (scope.ratio == null) && (scope.destinationHeight == null)) {
            scope.height = parseInt(window.getComputedStyle(element.parent()[0]).getPropertyValue('height'), 10);
            scope.ratio = scope.height / scope.width;
          }
          if (scope.destinationHeight && !scope.ratio) {
            scope.ratio = scope.destinationHeight / scope.destinationWidth;
          } else if (scope.ratio) {
            scope.destinationHeight = scope.destinationWidth * scope.ratio;
          }
          if (scope.ratio && !scope.height) {
            scope.height = scope.width * scope.ratio;
          }
          return true;
        };
        imageAreaEl = element[0].getElementsByClassName("step-2")[0];
        elOffset = function() {
          return elementOffset(imageAreaEl);
        };
        $input = element.find("input");
        $input.bind("change", function() {
          var file;
          file = this.files[0];
          return scope.setFiles(file);
        });
        $input.bind("click", function(e) {
          e.stopPropagation();
          return $input.val("");
        });
        scope.browseFiles = function() {
          if (navigator.camera) {
            return navigator.camera.getPicture(addTypeAndLoadImage, addPictureFailure, {
              destinationType: navigator.camera.DestinationType.DATA_URL,
              sourceType: navigator.camera.PictureSourceType.PHOTOLIBRARY
            });
          } else {
            return $input[0].click();
          }
        };
        scope.setFiles = function(file) {
          var reader;
          if (!file.type.match(/^image\//)) {
            return scope.$apply(function() {
              scope.cancel();
              return scope.dropError = "Wrong file type, please select an image.";
            });
          }
          scope.filename = file.name;
          scope.dropError = "";
          reader = new FileReader;
          reader.onload = function(e) {
            return loadImage(e.target.result);
          };
          return reader.readAsDataURL(file);
        };
        addPictureFailure = function() {
          return scope.$apply(function() {
            scope.cancel();
            return scope.dropError = "Failed to get a picture from your gallery";
          });
        };
        addTypeAndLoadImage = function(src) {
          return loadImage("data:image/jpeg;base64," + src);
        };
        loadImage = function(src, base64Src) {
          var img;
          if (base64Src == null) {
            base64Src = true;
          }
          if (!src) {
            return;
          }
          scope.state = "step-2";
          if (src !== scope.imgSrc) {
            scope.imgSrc = src;
            scope.imgLoaded = false;
            img = new Image;
            img.onerror = function() {
              return scope.$apply(function() {
                scope.cancel();
                return scope.dropError = "Unsupported type of image";
              });
            };
            img.onload = function() {
              var errors, height, width;
              width = img.width;
              height = img.height;
              errors = [];
              if (scope.width == null) {
                scope.width = scope.height * width / height;
              }
              if (width < scope.width) {
                errors.push("The image you dropped has a width of " + width + ", but the minimum is " + scope.width + ".");
              }
              minHeight = Math.min(scope.height, scope.destinationHeight);
              if (height < minHeight) {
                errors.push("The image you dropped has a height of " + height + ", but the minimum is " + minHeight + ".");
              }
              return scope.$apply(function() {
                if (errors.length) {
                  scope.cancel();
                  return scope.dropError = errors.join("<br/>");
                } else {
                  scope.imgLoaded = true;
                  $rootScope.$broadcast("cropme:loaded", width, height, element);
                  sendImageEvent("progress");
                  return startCropping(width, height);
                }
              });
            };
            if (!base64Src) {
              img.crossOrigin = "anonymous";
            }
            return img.src = src;
          }
        };
        moveCropZone = function(coords) {
          var offset;
          offset = elOffset();
          scope.xCropZone = coords.x - offset.left - scope.widthCropZone / 2;
          scope.yCropZone = coords.y - offset.top - scope.heightCropZone / 2;
          return checkBoundsAndSendProgressEvent();
        };
        moveBorders = {
          top: function(coords) {
            var y;
            y = coords.y - elOffset().top;
            scope.heightCropZone += scope.yCropZone - y;
            scope.yCropZone = y;
            checkVRatio();
            return checkBoundsAndSendProgressEvent();
          },
          right: function(coords) {
            var x;
            x = coords.x - elOffset().left;
            scope.widthCropZone = x - scope.xCropZone;
            checkHRatio();
            return checkBoundsAndSendProgressEvent();
          },
          bottom: function(coords) {
            var y;
            y = coords.y - elOffset().top;
            scope.heightCropZone = y - scope.yCropZone;
            checkVRatio();
            return checkBoundsAndSendProgressEvent();
          },
          left: function(coords) {
            var x;
            x = coords.x - elOffset().left;
            scope.widthCropZone += scope.xCropZone - x;
            scope.xCropZone = x;
            checkHRatio();
            return checkBoundsAndSendProgressEvent();
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
        checkBoundsAndSendProgressEvent = function() {
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
              checkVRatio();
            }
          }
          roundBounds();
          return debouncedSendImageEvent("progress");
        };
        roundBounds = function() {
          scope.yCropZone = Math.round(scope.yCropZone);
          scope.xCropZone = Math.round(scope.xCropZone);
          scope.widthCropZone = Math.round(scope.widthCropZone);
          return scope.heightCropZone = Math.round(scope.heightCropZone);
        };
        isNearBorders = function(coords) {
          var bottomLeft, bottomRight, h, offset, topLeft, topRight, w, x, y;
          offset = elOffset();
          x = scope.xCropZone + offset.left;
          y = scope.yCropZone + offset.top;
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
        dragIt = function(coords) {
          if (draggingFn) {
            return scope.$apply(function() {
              return draggingFn(coords);
            });
          }
        };
        getCropPromise = function() {
          var deferred;
          deferred = $q.defer();
          if (sendCropped()) {
            ctx.drawImage(imageEl, scope.xCropZone / zoom, scope.yCropZone / zoom, scope.croppedWidth, scope.croppedHeight, 0, 0, scope.destinationWidth, scope.destinationHeight);
            canvasToBlob(canvasEl, (function(blob) {
              return deferred.resolve(blob);
            }), "image/" + scope.type);
          } else {
            deferred.resolve();
          }
          return deferred.promise;
        };
        getOriginalPromise = function() {
          var deferred, originalCanvas, originalContext;
          deferred = $q.defer();
          if (sendOriginal()) {
            originalCanvas = document.createElement("canvas");
            originalContext = originalCanvas.getContext("2d");
            originalCanvas.width = imageEl.naturalWidth;
            originalCanvas.height = imageEl.naturalHeight;
            originalContext.drawImage(imageEl, 0, 0);
            canvasToBlob(originalCanvas, (function(blob) {
              return deferred.resolve(blob);
            }), "image/" + scope.type);
          } else {
            deferred.resolve();
          }
          return deferred.promise;
        };
        sendImageEvent = function(eventName) {
          scope.croppedWidth = scope.widthCropZone / zoom;
          scope.croppedHeight = scope.heightCropZone / zoom;
          return $q.all([getCropPromise(), getOriginalPromise()]).then(function(blobArray) {
            var result;
            result = {
              x: scope.xCropZone / zoom,
              y: scope.yCropZone / zoom,
              height: scope.croppedHeight,
              width: scope.croppedWidth,
              destinationHeight: scope.destinationHeight,
              destinationWidth: scope.destinationWidth,
              filename: scope.filename
            };
            if (blobArray[0]) {
              result.croppedImage = blobArray[0];
            }
            if (blobArray[1]) {
              result.originalImage = blobArray[1];
            }
            return $rootScope.$broadcast("cropme:" + eventName, result, element);
          });
        };
        debounce = function(func, wait, immediate) {
          var timeout;
          timeout = void 0;
          return function() {
            var args, callNow, context, later;
            context = this;
            args = arguments;
            later = function() {
              timeout = null;
              if (!immediate) {
                func.apply(context, args);
              }
            };
            callNow = immediate && !timeout;
            clearTimeout(timeout);
            timeout = setTimeout(later, wait);
            if (callNow) {
              func.apply(context, args);
            }
          };
        };
        scope.mousemove = function(e) {
          return scope.colResizePointer = (function() {
            switch (isNearBorders({
                  x: e.pageX - window.scrollX,
                  y: e.pageY - window.scrollY
                })) {
              case 'top':
                return 'ne-resize';
              case 'right':
              case 'bottom':
                return 'se-resize';
              case 'left':
                return 'sw-resize';
              default:
                return 'move';
            }
          })();
        };
        superswipe.bind(angular.element(element[0].getElementsByClassName('step-2')[0]), {
          'start': function(coords) {
            grabbedBorder = isNearBorders(coords);
            if (grabbedBorder) {
              draggingFn = moveBorders[grabbedBorder];
            } else {
              draggingFn = moveCropZone;
            }
            return dragIt(coords);
          },
          'move': function(coords) {
            return dragIt(coords);
          },
          'end': function(coords) {
            dragIt(coords);
            return draggingFn = null;
          }
        });
        scope.deselect = function() {
          return draggingFn = null;
        };
        scope.cancel = function($event, id) {
          if (id && element.attr('id') !== id) {
            return;
          }
          if ($event) {
            $event.preventDefault();
          }
          scope.dropLabel = "Drop files here";
          scope.dropClass = "";
          scope.state = "step-1";
          $rootScope.$broadcast("cropme:canceled");
          delete scope.imgSrc;
          return delete scope.filename;
        };
        scope.ok = function($event) {
          if ($event) {
            $event.preventDefault();
          }
          return sendImageEvent("done");
        };
        scope.$on("cropme:cancel", scope.cancel);
        scope.$on("cropme:ok", scope.ok);
        scope.$watch("src", function() {
          var delimit;
          if (scope.src) {
            scope.filename = scope.src;
            if (scope.src.indexOf("data:image") === 0) {
              return loadImage(scope.src);
            } else {
              delimit = scope.src.match(/\?/) ? "&" : "?";
              return loadImage("" + scope.src + delimit + "crossOrigin", false);
            }
          }
        });
        return debouncedSendImageEvent = debounce(sendImageEvent, 300);
      }
    };
  }]);

}).call(this);
;
/**
  * @ngdoc directive
  * @name dropbox
  * @requires elementOffset
  * @description
  * Simple directive to manage drag and drop of a file in an element
  *
 */

(function() {
  angular.module("cropme").directive("dropbox", ["elementOffset", function(elementOffset) {
    return {
      restrict: "E",
      link: function(scope, element, attributes) {
        var dragEnterLeave, dropbox, offset, reset;
        offset = elementOffset(element);
        reset = function(evt) {
          evt.stopPropagation();
          evt.preventDefault();
          return scope.$apply(function() {
            scope.dragOver = false;
            scope.dropText = "Drop files here";
            return scope.dropClass = "";
          });
        };
        dragEnterLeave = function(evt) {
          if (evt.x > offset.left && evt.x < offset.left + element[0].offsetWidth && evt.y > offset.top && evt.y < offset.top + element[0].offsetHeight) {
            return;
          }
          return reset(evt);
        };
        dropbox = element[0];
        scope.dropText = "Drop files here";
        scope.dragOver = false;
        dropbox.addEventListener("dragenter", dragEnterLeave, false);
        dropbox.addEventListener("dragleave", dragEnterLeave, false);
        dropbox.addEventListener("dragover", (function(evt) {
          var ok;
          evt.stopPropagation();
          evt.preventDefault();
          ok = evt.dataTransfer && evt.dataTransfer.types && evt.dataTransfer.types.indexOf("Files") >= 0;
          return scope.$apply(function() {
            scope.dragOver = true;
            scope.dropText = (ok ? "Drop now" : "Only files are allowed");
            return scope.dropClass = (ok ? "over" : "not-available");
          });
        }), false);
        return dropbox.addEventListener("drop", (function(evt) {
          var files;
          reset(evt);
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
  }]);

}).call(this);
;(function() {
  "use strict";

  /**
    * @ngdoc service
    * @name canvasToBlob
    * @requires -
    * @description
    * Service based on canvas-toBlob.js By Eli Grey, http://eligrey.com and Devin Samarin, https://github.com/eboyjr
    * Transform a html canvas into a blob that can then be uploaded as a file
    *
    * @example
  
  ```js
  angular.module("cropme").controller "myController", (canvasToBlob) ->
  	 * upload the french flag
  	uploader = (blob) ->
  		url = "http://my-awesome-server.com"
  		xhr = new XMLHttpRequest
  		xhr.setRequestHeader "Content-Type", blob.type
  		xhr.onreadystatechange = (e) ->
  			if @readyState is 4 and @status is 200
  				console.log "done"
  			else console.log "failed"  if @readyState is 4 and @status isnt 200
  		xhr.open "POST", url, true
  		xhr.send blob
  	canvas = document.createElement "canvas"
  	canvas.height = 100
  	canvas.width = 300
  	ctx = canvas.getContext "2d"
  	ctx.fillStyle = "#0000FF"
  	ctx.fillRect 0, 0, 100, 100
  	ctx.fillStyle = "#FFFFFF"
  	ctx.fillRect 100, 0, 200, 100
  	ctx.fillStyle = "#FF0000"
  	ctx.fillRect 200, 0, 300, 100
  	canvasToBlob canvas, uploader, "image/png"
  ```
   */
  angular.module("cropme").service("canvasToBlob", function() {
    var base64_ranks, decode_base64, is_base64_regex;
    is_base64_regex = /\s*;\s*base64\s*(?:;|$)/i;
    base64_ranks = void 0;
    decode_base64 = function(base64) {
      var buffer, code, i, last, len, outptr, rank, save, state, undef;
      len = base64.length;
      buffer = new Uint8Array(len / 4 * 3 | 0);
      i = 0;
      outptr = 0;
      last = [0, 0];
      state = 0;
      save = 0;
      rank = void 0;
      code = void 0;
      undef = void 0;
      while (len--) {
        code = base64.charCodeAt(i++);
        rank = base64_ranks[code - 43];
        if (rank !== 255 && rank !== undef) {
          last[1] = last[0];
          last[0] = code;
          save = (save << 6) | rank;
          state++;
          if (state === 4) {
            buffer[outptr++] = save >>> 16;
            if (last[1] !== 61) {
              buffer[outptr++] = save >>> 8;
            }
            if (last[0] !== 61) {
              buffer[outptr++] = save;
            }
            state = 0;
          }
        }
      }
      return buffer;
    };
    base64_ranks = new Uint8Array([62, -1, -1, -1, 63, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, -1, -1, -1, 0, -1, -1, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, -1, -1, -1, -1, -1, -1, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51]);
    return function(canvas, callback, type) {
      var args, blob, data, dataURI, header_end, is_base64;
      if (!type) {
        type = "image/png";
      }
      if (canvas.mozGetAsFile) {
        callback(canvas.mozGetAsFile("canvas", type));
        return;
      }
      args = Array.prototype.slice.call(arguments, 1);
      dataURI = canvas.toDataURL(type);
      header_end = dataURI.indexOf(",");
      data = dataURI.substring(header_end + 1);
      is_base64 = is_base64_regex.test(dataURI.substring(0, header_end));
      blob = void 0;
      if (Blob.fake) {
        blob = new Blob;
        if (is_base64) {
          blob.encoding = "base64";
        } else {
          blob.encoding = "URI";
        }
        blob.data = data;
        blob.size = data.length;
      } else if (Uint8Array) {
        if (is_base64) {
          blob = new Blob([decode_base64(data)], {
            type: type
          });
        } else {
          blob = new Blob([decodeURIComponent(data)], {
            type: type
          });
        }
      }
      return callback(blob);
    };
  });

}).call(this);
;(function() {
  "use strict";

  /**
    * @ngdoc service
    * @name elementOffset
    * @requires -
    * @description
    * Get the offset in pixel of an element on the screen
    *
    * @example
  
  ```js
  angular.module("cropme").directive "myDirective", (elementOffset) ->
  	link: (scope, element, attributes) ->
  		offset = elementOffset element
  		console.log "This directive's element is #{offset.top}px away from the top of the screen"
  		console.log "This directive's element is #{offset.left}px away from the left of the screen"
  		console.log "This directive's element is #{offset.bottom}px away from the bottom of the screen"
  		console.log "This directive's element is #{offset.right}px away from the right of the screen"
  ```
   */
  angular.module("cropme").service("elementOffset", function() {
    return function(el) {
      var height, offsetLeft, offsetTop, scrollLeft, scrollTop, width;
      if (el[0]) {
        el = el[0];
      }
      offsetTop = 0;
      offsetLeft = 0;
      scrollTop = 0;
      scrollLeft = 0;
      width = el.offsetWidth;
      height = el.offsetHeight;
      while (el) {
        offsetTop += el.offsetTop - el.scrollTop;
        offsetLeft += el.offsetLeft - el.scrollLeft;
        el = el.offsetParent;
      }
      return {
        top: offsetTop,
        left: offsetLeft,
        right: offsetLeft + width,
        bottom: offsetTop + height
      };
    };
  });

}).call(this);
