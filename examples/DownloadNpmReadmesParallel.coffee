###
This example will download the readmes from all npm modules hosted on github.
This script goes through the following steps:
1. download a list of all npm modules and save the list in "./npm.json"
2. guess at the name and location of each modules readme and download it
3. If download is successful save the readme and other meta data in "./npm/MODULE_NAME.json"

Note: This example downloads the readmes in parallel and is a simple modification
to "DownloadNpmReadmes.coffee". If you have not looked at "DownloadNpmReadmes.coffee" 
I suggest you look at it first.
###

# require dependencies and util functions
request = require 'request'
fs = require 'fs'
ctrl = require 'ctrl'
_ = require 'underscore'
trim=(str)->str.replace(/^\s+|\s+$/g,'')
#declare the function that will do all the work
downloadReadmes=()->
    data = require './npm.json' #this file will store all the repositores in npm
    #create a dir to save json files
    if !fs.existsSync('./npm') then fs.mkdirSync('./npm')
    data = _(data)
        #filter out items without repository url
        .filter((info)-> info.repository?.url? and trim(info.repository.url)!="")
        #add readme url to each info item
        .map((info)->
            info.readme = info.repository.url
                .replace(/git:\/\//mg,"https://")
                .replace(/\.git/mg,"")
                .replace(/git@github\.com:/mg,"https://github.com/")
                .replace(/(?:https?:)?\/\/github\.com\//mg, "https://raw.github.com/") + "/master/README.md"
            return info
        )
        #for each info item create a single step which will download the readme 
        #and save the corresponding .json file. Notice we are using ctrl to make 
        #substeps within the larger step.
        .map((info)->
                (step)->
                    ctrl([
                        #first download the readme
                        (step)->request(info.readme, step.next)
                        #save the file
                        (step, error, response, body)->
                            if error then step.next(error)
                            else if response.statusCode != 200 then step.next("Status code of #{response.statusCode} returned")
                            else
                                info.readme = body
                                fs.writeFile("./npm/" + info.name + ".json", JSON.stringify(info), step.next)
                        #log an error if there was one
                        (step, error)->
                            console.log info.name
                            if error then console.log error
                            step.next()
                    ],{errorHandler:(step,error)->console.log(error)},step.next)
        )
    #In order to make this download in parallel we are going to add a simple builder
    #that modifies the behavior of the next function so that 25 things are always
    #being downloaded at once.

    #First, we need to declare our custom builder
    parallelBuilder=(step, next)->
        oldNext = step.next
        currentStep = -1
        activeCount = 1
        step.next = ()->
            activeCount--
            #while we have not launched 25 threads and while we still have steps
            while activeCount < 25 and currentStep < step.steps.length
               currentStep++
               activeCount++
               oldNext.apply(null,arguments)
            #if there are no active threads and no steps left to be called
            #then make the final call to step.next triggering callback to be called
            if activeCount == 0 and currentStep == step.steps.length
                oldNext(null,arguments)
        next()
    #Second, need to make a custom runner that uses our new builder
    runner = new ctrl.CtrlRunner(ctrl.builders.next, parallelBuilder, ctrl.builders.data, ctrl.builders.errorHandler);
    #Third, we need to run the steps using our custom runner
    runner.run(data, {errorHandler:(step,error)->console.log(error); step.next()}, ()->console.log('done!'))

#download a list of all modules
if !fs.existsSync('./npm.json')
    ctrl([
        (step)->
            console.log('Downloading list of modules from npm...')
            step.next()
        (step)->request("https://registry.npmjs.org/-/all",step.next)
        (step, error, response, body)->
            if error then throw error
            else if response.statusCode != 200 then step.next("Status code of #{response.statusCode} returned when trying to get list of modules!")
            else fs.writeFile('./npm.json',body, step.next)
        (step, error)->
            if error then throw error
            else console.log "Downloaded list of modules from npm!"
            step.next()
    ],{},()->downloadReadmes())
else
    downloadReadmes()