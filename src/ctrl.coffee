copyArray=(array)->Array.prototype.slice.call(array)
isArray=(o) -> o? && Array.isArray o

builders = {
    ###{"name":"ctrl.builders.next", "priority":5}
    This builder adds the `next()` function to the step parameter. 
    It should normally be first in the list of builders.
    ###
    next:(step, next)->
        step.steps = copyArray(step.steps) #stop from being modified mid execution
        currentStep = -1
        step.next=()->
            currentStep++
            args = [step].concat(copyArray(arguments)) #create args to pass to next function
            if currentStep >= step.steps.length then step.callback.apply(null, args)
            else step.steps[currentStep].apply(null, args)
        next()
    ###{"name":"ctrl.builders.spawn", "priority":5}
    This builder adds the `spawn()` function to step object allowing 
    parallel operations.
    ###
    spawn:(step, next)->
        state = null
        class SpawnState
            constructor:(step, @callback)->
                @threadCount = -1
                @returnedThreads = -1
                @returnValues = {}
            spawn:()=>
                @threadCount++
                threadId = @threadCount
                return ()=> #notice => instead of ->
                    if @returnValues[threadId]? then throw "A spawn's callback can not be called multiple times!"
                    @returnValues[threadId] = (switch arguments.length
                        when 0 then null
                        when 1 then arguments[0]
                        else copyArray(arguments)
                    )
                    @returnedThreads++
                    @checkIfAllReturned()
            checkIfAllReturned:()->
                if @returnValues.length and @returnedThreads == @threadCount #if we are done spawning and all threads have been returned
                    @callback.apply(null, copyArray(@returnValues)) #call the next step passing in all the return values
                    state = null #we are now in a new step... reset back to spawn never being called
            doneSpawning:()->
                #spawning is done so we now know the length of the return values
                @returnValues.length = @threadCount + 1 #+1 because the first parm is the step object
                @checkIfAllReturned()
        oldNext = step.next
        step.spawn=()->
            if !state then state = new SpawnState(step, oldNext)
            return state.spawn()
        step.next=()->
            if state == null then oldNext.apply(null, arguments) #spawn was never called do nothing special
            else state.doneSpawning() #spawn was called
        next()
    ###{"name":"ctrl.builders.errorHandler", "priority":5}
    This builder adds error handling to the step object. 
    If a function is passed in as `errorHandler` to the options 
    parameter that function will be called in the event of an error.
    ###
    errorHandler:(step, next)->
        if !step.options.errorHandler then next(); return #there is no error handler registered so skip this module
        oldNext = step.next
        step.next=()->
            try
                oldNext.apply(null,arguments)
            catch error
                step.options.errorHandler(step, error)
        next()
    ###{"name":"ctrl.builders.data", "priority":5}
    This builder adds the `step.data` property allowing you to pass data 
    between steps. Additionally, if `data` is passed into the options its
     contents will be available to the first step.
    ###
    data:(step, next)->
        if step.options.data? then step.data = step.options.data
        else step.data = {}
        next()
}

###{"name":"ctrl.CtrlRunner(builders)", "priority":2}
Define a new instance of this class to create a new runner
that can have custom builders. When calling the constructor pass
in a list of builders to use.
###
class CtrlRunner
    constructor:(@builders)->
        if !isArray(@builders)
            ###{"name":"ctrl.CtrlRunner.builders", "priority":1}
            A array containing the list of the registered builders
            for this runner in the order they will be used.
            ###
            @builders = copyArray(arguments)
    ###{"name":"ctrl.CtrlRunner.run(steps, options={}, callback=(step)->)", "priority":1}
    Run the supplied steps. The builders currently in the `builders`
    array will be used to construct the steps object.
    ###
    run:(steps, options={}, callback=()->)=>
        step = {steps:steps, options:options, callback:callback}
        builders = copyArray(@builders) #stop from being modified mid construction
        currentModule = -1
        nextModule = ()->
            currentModule++
            if currentModule >= builders.length
                step.next() #run the steps!
            else builders[currentModule](step, nextModule)
        nextModule()

#export everything so it can be seen outside of this module
defaultCtrlRunner = new CtrlRunner(builders.next, builders.spawn, builders.data, builders.errorHandler)
###{"name":"ctrl(steps, options={}, callback=(step)->)", "priority":0}
Same as calling `ctrl.defaultCtrlRunner.run`.
###
extern = defaultCtrlRunner.run
extern.builders = builders
###{"name":"ctrl.defaultCtrlRunner", "priority":0}
The default CtrlRunner. To modify what happens when you call `ctrl(steps, options={}, callback=(step)->)`
modify `ctrl.defaultCtrlRunner.builders`.
###
extern.defaultCtrlRunner = defaultCtrlRunner
extern.CtrlRunner = CtrlRunner
if typeof module == "undefined" then window.ctrl = extern else module.exports = extern