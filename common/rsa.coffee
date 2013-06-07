fs = require "fs"
command = "openssl"
child_process = require "child_process"
createRandomFilePath = ()->
    return "/tmp/"+parseInt(Math.random()*10000000)
exports.generatePrivateKey = (callback)->
    tempPath = createRandomFilePath()
    genProcess = child_process.spawn command,["genrsa","-out",tempPath]
    genProcess.on "exit",(code)->
        if code isnt 0
            callback new Error "fail to call openssl"
            return
        fs.readFile tempPath,(err,data)->
            if err
                callback err
                return
            fs.unlink tempPath
            callback null,data
    #genProcess.stderr.pipe process.stderr
    
exports.generatePublicKey = (privateKey,callback)->
    tempPath = createRandomFilePath()
    fs.writeFileSync tempPath,privateKey
    pubProcess = child_process.spawn command,["rsa","-in",tempPath,"-pubout"]
    callbacked = false
    pubProcess.stdout.on "data",(data)->
        callbacked = true
        callback null,data.toString()
    pubProcess.on "exit",(code)->
        if code isnt 0 and not callbacked
            callback new Error "fail to call openssl"
        fs.unlink tempPath
    
    #pubProcess.stderr.pipe process.stderr
    
exports.encrypt = (data,publicKey,callback)->
    tempPath = createRandomFilePath()
    fs.writeFile tempPath,publicKey,(err)->
        callbacked = false
        if err
            callback err
            return
        encProcess = child_process.spawn command,["rsautl","-encrypt","-pubin","-inkey",tempPath]
        encProcess.stdout.on "data",(data)->
            callbacked = true
            callback null,data
        encProcess.on "exit",(code)->
            if code isnt 0 and not callbacked
                callback new Error "fail to call openssl"
            fs.unlink tempPath 
        encProcess.stdin.write data
        encProcess.stdin.end()
        
        #encProcess.stderr.pipe process.stderr
exports.decrypt = (data,privateKey,callback)->
    tempPath = createRandomFilePath()
    fs.writeFileSync tempPath,privateKey
    callbacked = false
    decProcess = child_process.spawn command,["rsautl","-decrypt","-inkey",tempPath]
    decProcess.stdout.on "data",(data)->
        callbacked = true
        callback null,data
    decProcess.on "exit",(code)->
        if code isnt 0 and not callbacked
            callback new Error "fail to call openssl"
        fs.unlink tempPath
    #decProcess.stderr.pipe process.stderr
    decProcess.stdin.write data
    decProcess.stdin.end()







