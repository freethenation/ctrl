copyArray=(array)->Array.prototype.slice.call(array)
isArray=(o) -> o? && Array.isArray o

builders = {
    next:(step, next)->
        step.steps = copyArray(step.steps) #stop from being modified mid execution
        currentStep = -1
        step.next=()->
            currentStep++
            args = [step].concat(copyArray(arguments)) #create args to pass to next function
            if currentStep >= step.steps.length then step.callback.apply(null, args)
            else step.steps[currentStep].apply(null, args)
        next()
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
    errorHandler:(step, next)->
        if !step.options.errorHandler then next(); return #there is no error handler registered so skip this module
        oldNext = step.next
        step.next=()->
            try
                oldNext.apply(null,arguments)
            catch error
                step.options.errorHandler(step, error)
        next()
    data:(step, next)->
        if step.options.data? then step.data = step.options.data
        else step.data = {}
        next()
}

class CtrlRunner
    constructor:(@builders)->
        if !isArray(@builders)
            @builders = copyArray(arguments)
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
extern = defaultCtrlRunner.run
extern.builders = builders
extern.defaultCtrlRunner = defaultCtrlRunner
extern.CtrlRunner = CtrlRunner
if typeof module == "undefined" then window.ctrl = extern else module.exports = extern