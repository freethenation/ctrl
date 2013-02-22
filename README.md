[![Build Status](https://travis-ci.org/freethenation/ctrl.png?branch=master)](https://travis-ci.org/freethenation/ctrl)
# ctrl
Simplifies asynchronous control flow in coffeescript making parallel code, synchronous code, and error handling simple
# Why make another control flow library?
___________________________
* One often desires to pass additional state to all the functions. Most of the control flow libraries I have seen do not allow for this. The issue can be worked around with a closure but closures are exactly what we are trying to avoid!
* There are tons of control flow libraries out there but none of them seem to play well with coffeescript; they all override `this` which does not play well with coffeescript's bound function (`()=>`) syntax.

# Features
___________________________
* Makes it easy to write synchronous code without nested callbacks
* Makes it easy to write parallel code without keeping track of all the pesky callbacks
* Allows all your functions to easily share state without using a closure
* Designed to be compatible with coffeescript's cool features
* Works in nodejs and the browser
* Is very extensible

# How to install
______________________________
    $ npm install ctrl
# Basic usage
_____________________________
ctrl is really easy to use and consists of a single function, `ctrl` to which you pass an array of functions to call.
The first parameter to each function is a reference to a `step` object which allows you to control the flow of the program. The signature for the `ctrl` function is 

```javascript
ctrl(arrayOfSteps, optionsObject={}, callback=function(){})
```

Lets look at a simple example

```javascript
var steps = [
    function (step) {
        console.log('working on the first thing');
        setTimeout(step.next, 300);
    },
    function (step) {
        console.log('working on second thing whos callback returns stuff');
        setTimeout(step.next, 300, 'someString', 6969);
    },
    function (step, someString, someNumber) {
        console.log('callback argument 1: ' + someString);
        console.log('callback argument 2: ' + someNumber);
        step.next();
    }
];
//ctrl = require('ctrl');
ctrl(steps, {}, function (step) {
    console.log('we are done!');
});
//The above code will print the following to console
//"working on the first thing"
//"working on second thing whos callback returns stuff"
//"callback argument 1: someString"
//"callback argument 2: 6969"
//"we are done!"
```

You can play with this example at [JSBin](http://jsbin.com/erapun/2/edit).

# Error handling
__________________________________
Any errors that are thrown can be handled by an error handler

```javascript
var errorHandler = function(step, error){
  console.log(error);
};
steps = [
    function (step) {
        console.log('working on the first thing');
        setTimeout(step.next, 300);
    },
    function (step) {
        console.log('i am going to throw an error');
        throw "error!";
    },
    function (step) {
      console.log("This function should never be called because there was an errror!");
    }
];
//ctrl = require('ctrl');
ctrl(steps, {errorHandler:errorHandler}, function (step) {
    console.log('This should not be called cause there was an error!');
});
//The above code will print the following to console
//"working on the first thing"
//"i am going to throw an error"
//"error!"
```

You can play with this example at [JSBin](http://jsbin.com/erapun/9/edit).

# Parallel code
_____________________________________
Using the spawn function on the step object you can run tasks in parallel and the next step will only be 
run when all of the tasks are complete

```javascript
steps = [
    function (step) {
      console.log('I am going to spawn 3!');
      setTimeout(step.spawn(), 300);
      setTimeout(step.spawn(), 500, 'string');
      setTimeout(step.spawn(), 100, 1,2);
      step.next();//call step.next to signal that we are done spawing
    },
    //return values are returned in the same order spawn is called in.
    //All the return values for a given function are returned as a single parameter
    //If no values are returned null is returned if multible values are returned an array is returned
    function (step, arg1, arg2, arg3) {
      console.log(arg1);//arg1 = null
      console.log(arg2);//arg2 = 'string'
      console.log(arg3);//arg3 = [1,2]
      step.next();
    }
];
//ctrl = require('ctrl');
ctrl(steps, {}, function (step) {
    console.log('we are done!');
});
//The above code will print the following to console
//"I am going to spawn 3!"
//null
//"string"
//[1, 2]
//"we are done!"
```

You can play with this example at [JSBin](http://jsbin.com/erapun/15/edit).

# Sharing state
________________________
You can share state by using `step.data` which is passed to all the functions.

```javascript
steps = [
  function (step) {
    console.log(step.data.shared);
    step.data.shared = "string has been changed once";
    step.next();
  },
  function (step) {
    console.log(step.data.shared);
    step.data.shared = "string has been changed twice";
    step.next();
  }
];
//ctrl = require('ctrl');
ctrl(steps, {data:{shared:'inital string'}}, function (step) {
  console.log(step.data.shared); 
  console.log('we are done!');
});
//The above code will print the following to console
//"inital string"
//"string has been changed once"
//"string has been changed twice"
//"we are done!"
```

You can play with this example at [JSBin](http://jsbin.com/erapun/16/edit).

# Extending
_______________________
If you have ever written custom middleware for connect then you should be familiar with the mechanism by which ctrl can be extended. The step object is built up layer by layer by a series of builder functions. Each builder function extends the step object in some specific way. The signature for a builder function is `function(step, next)`. An example should clarify things. 

```javascript
//The logger builder logs all parameters passed to step.next
var loggingBuilder = function(step, next){
  var oldNext = step.next;
  step.next = function(){
    //print the arguments passed to step.next
    console.log("Next was called with the parameters:");
    console.log(Array.prototype.slice.call(arguments));
    oldNext.apply(null, arguments); //call the original step
  };
  next(); //dont forget to call next to signal that your custom builder is done
};

//create a new CtrlRunner. When you call `Ctrl()` you are using 
//the default runner by createing a new runner we can customize 
//what builders are used to construct the `step` parameter.
var customRunner = new ctrl.CtrlRunner(ctrl.builders.next, ctrl.builders.spawn,
  loggingBuilder, ctrl.builders.data, ctrl.builders.errorHandler);

//we are now going to run the new CtrlRunner that has our custom builder
customRunner.run([
  function (step) {
    step.next("parm1", "parm2");
  },
  function (step) {
    step.next(1, 2);
  }
], {}, function(step){console.log('we are done!');});

//The above code will print the following to console:
//"Next was called with the parameters:"
//[]
//"Next was called with the parameters:"
//["parm1", "parm2"]
//"Next was called with the parameters:"
//[1, 2]

//Notice next was called 3 time. Next is called initially to start running the steps
```

You can play with this example at [JSBin](http://jsbin.com/erapun/37/edit).

The api documentation for the library can be found [here](https://github.com/freethenation/ctrl/blob/master/doc/api.md).