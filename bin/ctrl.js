(function() {
  var CtrlRunner, copyArray, defaultCtrlRunner, extern, isArray, modules,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  copyArray = function(array) {
    return Array.prototype.slice.call(array);
  };

  isArray = function(o) {
    return (o != null) && Array.isArray(o);
  };

  modules = {
    next: function(ctrl, next) {
      var currentStep;
      ctrl.steps = copyArray(ctrl.steps);
      currentStep = -1;
      ctrl.next = function() {
        var args;
        currentStep++;
        args = [ctrl].concat(copyArray(arguments));
        if (currentStep >= ctrl.steps.length) {
          return ctrl.callback(args);
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

          this.threadCount = 0;
          this.returnedThreads = 0;
          this.returnValues = {
            0: ctrl
          };
        }

        SpawnState.prototype.spawn = function() {
          var _this = this;
          this.threadCount++;
          return function() {
            if (_this.returnValues[_this.threadCount] != null) {
              throw "A spawn's callback can not be called multiple times!";
            }
            _this.returnValues[_this.threadCount] = copyArray(arguments);
            _this.returnedThreads++;
            return _this.checkIfAllReturned();
          };
        };

        SpawnState.prototype.checkIfAllReturned = function() {
          if (this.returnValues.length && this.returnehdThreads === this.threadCount) {
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

    function CtrlRunner(modules) {
      this.modules = modules;
      this.run = __bind(this.run, this);

      if (!isArray(this.modules)) {
        this.modules = copyArray(arguments);
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
      modules = copyArray(this.modules);
      currentModule = -1;
      nextModule = function() {
        currentModule++;
        if (currentModule >= modules.length) {
          return ctrl.next();
        } else {
          return modules[currentModule](ctrl, nextModule);
        }
      };
      return nextModule();
    };

    return CtrlRunner;

  })();

  defaultCtrlRunner = new CtrlRunner(modules.next, modules.spawn, modules.data, modules.errorHandler);

  extern = defaultCtrlRunner.run;

  extern.modules = modules;

  extern.defaultCtrlRunner = defaultCtrlRunner;

  extern.CtrlRunner = CtrlRunner;

  if (typeof module === "undefined") {
    window.ctrl = extern;
  } else {
    module.exports = extern;
  }

}).call(this);