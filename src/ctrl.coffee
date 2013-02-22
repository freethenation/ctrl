copyArray=(array)->Array.prototype.slice.call(array)
isArray=(o) -> o? && Array.isArray o

modules = {
    next:(ctrl, next)->
        ctrl.steps = copyArray(ctrl.steps) #stop from being modified mid execution
        currentStep = -1
        ctrl.next=()->
            currentStep++
            args = [ctrl].concat(copyArray(arguments)) #create args to pass to next function
            if currentStep >= ctrl.steps.length then ctrl.callback.apply(null, args)
            else ctrl.steps[currentStep].apply(null, args)
        next()
    spawn:(ctrl, next)->
        state = null
        class SpawnState
            constructor:(ctrl, @callback)->
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
                @returnValues.length = @threadCount + 1 #+1 because the first parm is the ctrl object
                @checkIfAllReturned()
        oldNext = ctrl.next
        ctrl.spawn=()->
            if !state then state = new SpawnState(ctrl, oldNext)
            return state.spawn()
        ctrl.next=()->
            if state == null then oldNext.apply(null, arguments) #spawn was never called do nothing special
            else state.doneSpawning() #spawn was called
        next()
    errorHandler:(ctrl, next)->
        if !ctrl.options.errorHandler then next(); return #there is no error handler registered so skip this module
        oldNext = ctrl.next
        ctrl.next=()->
            try
                oldNext.apply(null,arguments)
            catch error
                ctrl.options.errorHandler(ctrl, error)
        next()
    data:(ctrl, next)->
        if ctrl.options.data? then ctrl.data = ctrl.options.data
        else ctrl.data = {}
        next()
}

class CtrlRunner
    constructor:(@modules)->
        if !isArray(@modules)
            @modules = copyArray(arguments)
    run:(steps, options={}, callback=()->)=>
        ctrl = {steps:steps, options:options, callback:callback}
        modules = copyArray(@modules) #stop from being modified mid construction
        currentModule = -1
        nextModule = ()->
            currentModule++
            if currentModule >= modules.length
                ctrl.next() #run the steps!
            else modules[currentModule](ctrl, nextModule)
        nextModule()

#export everything so it can be seen outside of this module
defaultCtrlRunner = new CtrlRunner(modules.next, modules.spawn, modules.data, modules.errorHandler)
extern = defaultCtrlRunner.run
extern.modules = modules
extern.defaultCtrlRunner = defaultCtrlRunner
extern.CtrlRunner = CtrlRunner
if typeof module == "undefined" then window.ctrl = extern else module.exports = extern