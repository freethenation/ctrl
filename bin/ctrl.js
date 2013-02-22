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
    next: function(step, next) {
      var currentStep;
      step.steps = copyArray(step.steps);
      currentStep = -1;
      step.next = function() {
        var args;
        currentStep++;
        args = [step].concat(copyArray(arguments));
        if (currentStep >= step.steps.length) {
          return step.callback.apply(null, args);
        } else {
          return step.steps[currentStep].apply(null, args);
        }
      };
      return next();
    },
    spawn: function(step, next) {
      var SpawnState, oldNext, state;
      state = null;
      SpawnState = (function() {

        function SpawnState(step, callback) {
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
      oldNext = step.next;
      step.spawn = function() {
        if (!state) {
          state = new SpawnState(step, oldNext);
        }
        return state.spawn();
      };
      step.next = function() {
        if (state === null) {
          return oldNext.apply(null, arguments);
        } else {
          return state.doneSpawning();
        }
      };
      return next();
    },
    errorHandler: function(step, next) {
      var oldNext;
      if (!step.options.errorHandler) {
        next();
        return;
      }
      oldNext = step.next;
      step.next = function() {
        try {
          return oldNext.apply(null, arguments);
        } catch (error) {
          return step.options.errorHandler(step, error);
        }
      };
      return next();
    },
    data: function(step, next) {
      if (step.options.data != null) {
        step.data = step.options.data;
      } else {
        step.data = {};
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
      var currentModule, nextModule, step;
      if (options == null) {
        options = {};
      }
      if (callback == null) {
        callback = function() {};
      }
      step = {
        steps: steps,
        options: options,
        callback: callback
      };
      builders = copyArray(this.builders);
      currentModule = -1;
      nextModule = function() {
        currentModule++;
        if (currentModule >= builders.length) {
          return step.next();
        } else {
          return builders[currentModule](step, nextModule);
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
