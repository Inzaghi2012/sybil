rpc = require "../common/rpc.coffee"
rsa = require "../common/rsa.coffee"
class PublicSession extends rpc.RPCServer
    constructor:(tunnel,server,main)->
        @main = main
        super(tunnel)
        console.assert tunnel instanceof rpc.NodeWSTunnel
        @nodeIp = tunnel.ws._socket.remoteAddress
        @date = new Date()
        @declare "getNodes","count"
        @declare "getPublicKey"
        @declare "autherize","data"
        @declare "pushInfo","data"
        @server = server
    close:()->
        @tunnel.close()
    getNodes:(count,callback)->
        callback null,(@server.getNodes count)
    getPublicKey:(callback)->
        callback null,@server.rsa.publicKey
    requestAutherize:(callback)->
        @main.autherizeNode @nodeIp
        callback null
    autherize:(base64Data,callback)->
        data = new Buffer(base64Data,"base64")
        rsa.decrypt data,@server.rsa.privateKey,(err,data)->
            if err
                console.log "fail to autherize",base64Data
                callback err
                return
            callback null,(data.toString("base64"))
    pushInfo:(data,callback)->
        node = @main.getAuthedNodeByIp(@nodeIp)
        if not node
            callback new Error "not autherized"
            @main.autherizeNode @nodeIp
            return
        console.log "recieve info",data,typeof data
        if data.type is "message"
            @main.app.onMessage node,data.data
        else if data.type is "share"
            @main.app.onShare node,data.data
        callback(null)
    
exports.PublicSession = PublicSession