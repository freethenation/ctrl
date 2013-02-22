fs = require 'fs'
ctrllib = require './src/ctrl.coffee'
_ = require 'underscore'
childProcess = require 'child_process'
flatten = _.flatten

createMinJsSteps=()->
    createCompileSteps=(filename)->
        return [
            (ctrl)->readFile(filename, ctrl.next)
            (ctrl, file)->compress(file, ctrl.next)
            (ctrl, file)->writeFile(filename.replace(".js",".min.js"), file, ctrl.next)
        ]
    return [
        (ctrl)->require('glob')("bin/*.js", ctrl.next)
        (ctrl, error, files)->
            files = (f for f in files when f.indexOf(".min.") == -1)
            console.log "Minifying the following js files:"
            console.log files
            ctrllib(flatten(createCompileSteps(f) for f in files), {}, ctrl.next)
    ]

createBuildSteps=()->
    return [
        (ctrl)->readFile("./src/ctrl.coffee", ctrl.next)
        (ctrl, file)->compile(file, ctrl.next)
        (ctrl, file)->writeFile("./bin/ctrl.js", file, ctrl.next)
    ]

createTestSteps=()->
    return [
        (ctrl)->test('./tests/tests.coffee', ctrl.data.exception, ctrl.next)
    ]

createGenDocStesp=()->
    return [
        (ctrl)->readFile("./src/ctrl.coffee", ctrl.next)
        (ctrl, file)->genApiDoc(file, ctrl.next)
        (ctrl, file)->writeFile("./doc/api.md", file, ctrl.next)
    ] 

option '-e', '--exception', "don't catch exceptions when running unit tests"
task 'build', 'builds ctrl', (options)->
    ctrllib(createBuildSteps(),{data:options})

task 'build:min', 'builds a minimized version of ctrl', (options)->
    ctrllib([].concat(createBuildSteps(), createMinJsSteps()),{data:options})

task 'build:full', 'builds a minimized version of ctrl and runs unit tests', (options)->
    ctrllib([].concat(createBuildSteps(), createMinJsSteps(), createTestSteps()),{data:options})

task 'build:doc', 'builds api doc for ctrl', (options)->
    ctrllib(createGenDocStesp(),{data:options})


replaceAll = (txt, replace, with_this)->
  return txt.replace(new RegExp(replace, 'g'),with_this)

genApiDoc = (inputFile, callback)->
    matches = []
    r = /(\s*)###(\{[^\r\n]*\})([\s\S]*?)###/mg;
    match = r.exec(inputFile)
    while (match != null)
        matches.push {json:JSON.parse(match[2]), doc:replaceAll(match[3], match[1],"")}
        match = r.exec(inputFile)
    matches.sort((i)->-i.json?.priority || 666)
    matches = ("### #{m.json.name}\n\n#{m.doc}\n\n" for m in matches)
    callback(matches.join(""))

compile = (inputFile, callback) ->
    coffee = require 'coffee-script'
    callback?(coffee.compile(inputFile))

compress = (inputFile, callback) ->
    UglifyJS = require "uglify-js"
    toplevel = UglifyJS.parse(inputFile)
    toplevel.figure_out_scope()
    compressor = UglifyJS.Compressor()
    compressed_ast = toplevel.transform(compressor)
    compressed_ast.figure_out_scope()
    compressed_ast.compute_char_frequency()
    compressed_ast.mangle_names()
    callback?(compressed_ast.print_to_string())

compressCss = (inputFile, callback) ->
    callback?(require('clean-css').process(inputFile))
    
readFile = (filename, callback) ->
    data = fs.readFile(filename, 'utf8', (err, data)-> if err then throw err else callback(data))
 
writeFile = (filename, data, callback) ->
    fs.writeFile(filename, data, 'utf8', (err)-> if err then throw err else callback())

test = (inputFileName, throwException, callback) ->
    tests = require(inputFileName)
    tests.RunAll(throwException)
    callback()