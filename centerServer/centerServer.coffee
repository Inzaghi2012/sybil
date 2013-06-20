rpc = require "../../node-common-rpc/lib/rpc.coffee"
rsa = require "../common/rsa.coffee"
config = require  "../config/centerServerConfig.coffee"
events = require "events"
ServerError = new Error()
ServerError.name = "ServerError"
AuthError = new Error()
AuthError.name = "AuthError"
ViolationError = new Error()
ViolationError.name = "ViolationError" 
class NodeChecker extends events.EventEmitter
    constructor:(server)->
        @checkInterval = 500
# rpc auth(pubkey,callback) | auth the rpcSession
# rpc register(password,callback) | add the client to nodeList
# rpc getNodes(password,callback) | 
class CenterServer extends rpc.RPCServer
    constructor:()->
        super new rpc.WebSocketGateway(config.port,config.host)
        @nodeList = []
        @sessions = []
        @maxChangePassword = 50
        @declare "auth"
        @declare "register"
        @declare "getNodes"
    getNodes:(password,count,callback)->
        if password is callback.client.password
            callback AuthError
            return
        if not count
            count = 500
        if nodeList.length <= count
            callback null,@nodeList
            return
        if not @_nodeListIndex
            @_nodeListIndex = 0
        results = []
        for _ in [0...count]
            if @nodeListIndex >= @nodeList.length
                @nodeListIndex = 0
            results.push @nodeListp[@nodeListIndex]
            @nodeListIndex++
        callback null,results
    register:(password,callback)->
        if password isnt callback.client.password 
            callback AuthError
            return
        for item in @nodeList
            if item.address is callback.client.address
                # already in nodeList
                # update the date
                item.date = Date.now()
                callback null,false
                return
        @nodeList.push {address:callback.client.address,date:Date.now()}
        callback null,true
    auth:(pubkey,callback)->
        client = callback.client
        client.pubkey = pubkey
        client.password = Math.random().toString()
        callback rsa.encrypt password,pubkey,(err,passwordEnc)=>
            if err
                callback ServerError
                return
            hasClient = false
            for session in @sessions
                if session.client is client
                    hasClient = true
                    session.client.changePassword = session.client.changePassword or 0
                    session.client.changePassword++
                    if session.client.changePassword >= @maxChangePassword
                        callback ViolationError
                        return
            if not hasClient
                @sessions.push {client:client}
                client.on "close" ,()=>
                    for session,index in @sessions
                        if session.client is client
                            @sessions.splice(index,1)
            
main = ()->
    centerServer = new CenterServer()
    serverWatcher = new rpc.RPCServer(new rpc.WebSocketGateway(2013,"localhost"))
    serverWatcher.serve {
        getServerStatistics:(callback)->
            result = ""
            result += "server nodes count:#{centerServer.nodeList.length}\n"
            result += "server session count:#{centerServer.sessions.length}\n"
            callback null,result
            
    }
process.cleanUp = ()->
    rpc.Gateway.clear()
process.safeExit = (code)->
    process.cleanUp()
    process.exit(code or 0)
process.on "SIGINT",process.safeExit
process.on "SIGTERM",process.safeExit
process.on "uncatchException",(err)->console.error "UncatchException",err
main()
