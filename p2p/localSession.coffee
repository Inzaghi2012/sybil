rpc = require "../common/rpc.coffee"
NodeInterface = (require "./nodeInterface.coffee").NodeInterface
class LocalSession extends rpc.RPCServer
    constructor:(tunnel,server)->
        @server = server
        super(tunnel)
        @declare "sendMessage","guid","content"
        @declare "share","info"
        @declare "getAuthedNodes"
    sendMessage:(guid,message,callback)->
        for item in @server.authedNodeList
            console.log item,item.guid,guid
            if item.guid.toString() is guid
                inf = new NodeInterface(item.ips[0])
                inf.pushInfo {type:"message",data:message}
                console.log "sent"
                callback null
                return
        console.log "fail to sent"
        callback new Error "invalid guid"
        return
                    
                
    getAuthedNodes:(callback)->
        callback null,@server.authedNodeList
    share:(info,callback)->
        @server.boardCast {type:"share",data:info}
        
exports.LocalSession = LocalSession