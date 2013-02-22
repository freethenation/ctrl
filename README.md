[![build status](https://secure.travis-ci.org/freethenation/ctrl.png)](http://travis-ci.org/freethenation/ctrl)
# ctrl
Simplifies asynchronous control flow in coffeescript making parallel code, synchronous code, and error handling simple
# Why make another control flow library?
___
* One often desires to pass additional state to all the functions. Most of the control flow libraries I have seen do not allow for this. The issue can be worked around with a closure but closures are exactly what we are trying to avoid!
* There are tons of control flow libraries out there but none of them seem to play well with coffeescript; they all override `this` which does not play well with coffeescript's bound function (`()=>`) syntax.

# Features
___
* Makes it easy to write synchronous code without nested callbacks
* Makes it easy to write parallel code without keeping track of all the pesky callbacks
* Allows all your functions to easily share state without using a closure
* Designed to be compatible with coffeescript's cool features
* Works in nodejs and the browser
* Is very extensible

# How to install
___
    $ npm install ctrl
# Basic usage
___
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
___
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
___
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
___
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