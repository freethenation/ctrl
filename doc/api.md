### ctrl.builders.next

This builder adds the `next()` function to the step parameter. It should normally be first in the list of builders.

### ctrl.builders.spawn

This builder adds the `spawn()` function to step object allowing parallel operations.

### ctrl.builders.errorHandler

This builder adds error handling to the step object. If a function is passed in as `errorHandler` to the options parameter that function will be called in the event of an error.

### ctrl.builders.data

This builder adds the `step.data` property allowing you to pass data between steps. Additionally, if `data` is passed into the options its contents will be available to the first step.

### ctrl.CtrlRunner(builders)


Define a new instance of this class to create a new runner
that can have custom builders. When calling the constructor pass
in a list of builders to use.


### ctrl.CtrlRunner.builders

A array containing the list of the registered buildersfor this runner in the order they will be used.

### ctrl.CtrlRunner.run(steps, options={}, callback=(step)->)

Run the supplied steps. The builders currently in the `builders`array will be used to construct the steps object.

### ctrl.defaultCtrlRunner

The default CtrlRunner. To modify what happens when you call `ctrl(steps, options={}, callback=(step)->)`modify `ctrl.defaultCtrlRunner.builders`.

### ctrl(steps, options={}, callback=(step)->)

Same as calling `ctrl.defaultCtrlRunner.run`.

