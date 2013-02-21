#General Util Functions
str=(obj)->
    if obj == null then "null"
    else if typeof obj == "undefined" then "undefined"
    else obj.toString()

#General Testing Code
class Test
    constructor:(@name, @func)->
        @num = 0
    expect:(num)=>
        @num = num
    equal:(arg1, arg2, message="''")=>
        @num--
        if arg1 != arg2 then throw "NotEqual: '#{str(arg1)}' does not equal '#{str(arg2)}'\n   #{message}"
    deepEqual:(arg1, arg2, message="")=>
        @num--
        if not require('deep-equal')(arg1, arg2) then throw "NotEqual: '#{str(arg1)}' does not equal '#{str(arg2)}'\n   #{message}"
    ok:(bool,message="")=>
        @num--
        if not bool then throw "NotOk: false was passed to ok\n   #{message}"
    done:(message="")=>
        if @num != 0 then throw "NotDone: #{str(@num)} more checks were expected before done was called\n   #{message}"
    run:()=>
        @func.call(this)
        @done()
        
test=(name, func)->
    t = new Test(name, func)
    exports[name]=()->t.run()

exports.RunAll = (throwException)->
    for name of exports
        if name != "RunAll"
            if throwException then exports[name]()
            else
                try
                    exports[name]()
                catch ex
                    console.log "Error in Test '#{name}'"
                    console.log "Message: #{ex}"
                    console.log "Stack:\n#{ex.stack}"
                    console.log ''
    console.log "All tests have been run!"
    return

# ctrl specific code
    
callMeBack=(func, args...)->
    func.apply(null, args)

ctrl=require("../src/ctrl.coffee")

test "Basic Next Test", ()->
    runner = new ctrl.CtrlRunner(ctrl.modules.next)
    steps = []
    steps.push (ctrl)=>
        callMeBack(ctrl.next, 1, 2, 3)
    steps.push (ctrl)=>
        callMeBack(ctrl.next)
    runner.run(steps, {}, @done)

test "CallbackParameters", ()->
    @expect(2)
    ctrl([
        (ctrl)=>
            callMeBack(ctrl.next, 1, 2)
        (ctrl, arg1, arg2)=>
            @equal(arg1, 1)
            @equal(arg2, 2)
            callMeBack(ctrl.next)
    ], {}, @done)

test "ParallelCode", ()->
    ctrl([
        (ctrl)=>
            callMeBack(ctrl.spawn())
            callMeBack(ctrl.spawn())
            callMeBack(ctrl.spawn())
            ctrl.next()
    ], {}, @done)

test "BasicErrorHandling", ()->
    ok = @ok
    handler = (ctrl, error)->
        ok(ctrl == ctrl)
        ok(error.toString() == "some error")
    @expect(2)
    ctrl([
        (ctrl)=>
            throw "some error"
        (ctrl)=>
            @ok(false, "this code should have never been reached")
    ], {errorHandler:handler}, @done)

test "ParallelErrorHandling", ()->
    @expect(2)
    ok = @ok
    handler = (ctrl, error)->
        ok(ctrl == ctrl)
        ok(error.toString() == "some error")
    ctrl([
        (ctrl)=>
            callMeBack(ctrl.spawn())
            callMeBack(ctrl.spawn())
            throw "some error"
            ctrl.next()
        (ctrl, err)=>
            @ok(false, "this code should have never been reached")
            ctrl.next()
    ], {errorHandler:handler}, @done)

test "BubbleErrorHandling", ()->
    @expect(1)
    exThrown = false
    try
        ctrl([(ctrl, err)->ctrl.raise("some error")])
    catch ex
        exThrown = true
    @ok(exThrown)
    @done()
    
test "DontCatchExceptions", ()->
    @expect(1)
    exThrown = false
    try
        ctrl([(ctrl)->math.kj], {catchExceptions:false}, {}, ()->)
    catch ex
        exThrown = true
    @ok(exThrown)
    @done()

test "NoCallback", ()->
    @expect(1)
    ctrl([
        (ctrl)=>
            @ok(true)
    ])
    @done()

test "BasicStateTest", ()->
    @expect(4)
    sharedState = {
        sharedstr: "not modified"
        sharedfunc: ()->true
    }
    ctrl([
        (ctrl)=>
            @equal("not modified", ctrl.data.sharedstr)
            @equal(true, ctrl.data.sharedfunc())
            ctrl.data.sharedstr = "modified"
            ctrl.data.sharedfunc = ()->false
            ctrl.next()
        (ctrl)=>
            @equal("modified", ctrl.data.sharedstr)
            @equal(false, ctrl.data.sharedfunc())
            ctrl.next()
    ], {data:sharedState}, @done)

#if script is called directly run all the tests
if !module.parent
    exports.RunAll()