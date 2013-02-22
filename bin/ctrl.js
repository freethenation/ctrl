(function() {
  var CtrlRunner, builders, copyArray, defaultCtrlRunner, extern, isArray,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  copyArray = function(array) {
    return Array.prototype.slice.call(array);
  };

  isArray = function(o) {
    return (o != null) && Array.isArray(o);
  };

  builders = {
    next: function(ctrl, next) {
      var currentStep;
      ctrl.steps = copyArray(ctrl.steps);
      currentStep = -1;
      ctrl.next = function() {
        var args;
        currentStep++;
        args = [ctrl].concat(copyArray(arguments));
        if (currentStep >= ctrl.steps.length) {
          return ctrl.callback.apply(null, args);
        } else {
          return ctrl.steps[currentStep].apply(null, args);
        }
      };
      return next();
    },
    spawn: function(ctrl, next) {
      var SpawnState, oldNext, state;
      state = null;
      SpawnState = (function() {

        function SpawnState(ctrl, callback) {
          this.callback = callback;
          this.spawn = __bind(this.spawn, this);

          this.threadCount = -1;
          this.returnedThreads = -1;
          this.returnValues = {};
        }

        SpawnState.prototype.spawn = function() {
          var threadId,
            _this = this;
          this.threadCount++;
          threadId = this.threadCount;
          return function() {
            if (_this.returnValues[threadId] != null) {
              throw "A spawn's callback can not be called multiple times!";
            }
            _this.returnValues[threadId] = ((function() {
              switch (arguments.length) {
                case 0:
                  return null;
                case 1:
                  return arguments[0];
                default:
                  return copyArray(arguments);
              }
            }).apply(_this, arguments));
            _this.returnedThreads++;
            return _this.checkIfAllReturned();
          };
        };

        SpawnState.prototype.checkIfAllReturned = function() {
          if (this.returnValues.length && this.returnedThreads === this.threadCount) {
            this.callback.apply(null, copyArray(this.returnValues));
            return state = null;
          }
        };

        SpawnState.prototype.doneSpawning = function() {
          this.returnValues.length = this.threadCount + 1;
          return this.checkIfAllReturned();
        };

        return SpawnState;

      })();
      oldNext = ctrl.next;
      ctrl.spawn = function() {
        if (!state) {
          state = new SpawnState(ctrl, oldNext);
        }
        return state.spawn();
      };
      ctrl.next = function() {
        if (state === null) {
          return oldNext.apply(null, arguments);
        } else {
          return state.doneSpawning();
        }
      };
      return next();
    },
    errorHandler: function(ctrl, next) {
      var oldNext;
      if (!ctrl.options.errorHandler) {
        next();
        return;
      }
      oldNext = ctrl.next;
      ctrl.next = function() {
        try {
          return oldNext.apply(null, arguments);
        } catch (error) {
          return ctrl.options.errorHandler(ctrl, error);
        }
      };
      return next();
    },
    data: function(ctrl, next) {
      if (ctrl.options.data != null) {
        ctrl.data = ctrl.options.data;
      } else {
        ctrl.data = {};
      }
      return next();
    }
  };

  CtrlRunner = (function() {

    function CtrlRunner(builders) {
      this.builders = builders;
      this.run = __bind(this.run, this);

      if (!isArray(this.builders)) {
        this.builders = copyArray(arguments);
      }
    }

    CtrlRunner.prototype.run = function(steps, options, callback) {
      var ctrl, currentModule, nextModule;
      if (options == null) {
        options = {};
      }
      if (callback == null) {
        callback = function() {};
      }
      ctrl = {
        steps: steps,
        options: options,
        callback: callback
      };
      builders = copyArray(this.builders);
      currentModule = -1;
      nextModule = function() {
        currentModule++;
        if (currentModule >= builders.length) {
          return ctrl.next();
        } else {
          return builders[currentModule](ctrl, nextModule);
        }
      };
      return nextModule();
    };

    return CtrlRunner;

  })();

  defaultCtrlRunner = new CtrlRunner(builders.next, builders.spawn, builders.data, builders.errorHandler);

  extern = defaultCtrlRunner.run;

  extern.builders = builders;

  extern.defaultCtrlRunner = defaultCtrlRunner;

  extern.CtrlRunner = CtrlRunner;

  if (typeof module === "undefined") {
    window.ctrl = extern;
  } else {
    module.exports = extern;
  }

}).call(this);
