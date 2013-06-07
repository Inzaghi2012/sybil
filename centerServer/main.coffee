rpc = require "../common/rpc.coffee"
config = require "../config/centerServer.coffee"
nodeConfig =require "../config/p2pnode.coffee"
events = require "events"
EventEmitter = events.EventEmitter
ws = require "ws"
WebSocket = ws
WebSocketServer = ws.Server
port = config.port
nodePort = nodeConfig.port
# the core functionality of center server is to provide
# client ability to others IP
# The center is used to collect the IP's the clients report to it
class Server extends EventEmitter
    constructor:(tunnel)->
        @nodeList = []
        @maxNodeCountReturn = 50
        @server = new WebSocketServer({port:port})
        @getCountIndex = 0
        @_buildServer()
        setInterval (()=>
            console.log @nodeList
            ),5000
    _buildServer:()->
        @server.on "connection",(ws)=>
            useIt = false
            session = new NodeSession(new rpc.NodeWSTunnel(ws))
            console.log "try add to sessions",session.nodeIp
            for item,index in @nodeList
                if item.nodeIp is session.nodeIp
                    @nodeList.splice index,1
                    @nodeList.push session
                    useIt = true
                    break
            console.log "useIt",useIt
            if not useIt
                @nodeList.push session
            session.on "getNodes",(count,callback)=>
                console.log "getNodes called"
                if count > @maxNodeCountReturn
                    count = @maxNodeCountReturn
                if @nodeList.length is 0
                    callback(null,[])
                index = @getCountIndex
                results = []
                
                while true
                    while @nodeList.length > index
                        results.push @nodeList[index].nodeIp
                        if results.length >= count
                            break
                        index++
                        if index is @getCountIndex
                            break
                    if results.length >= count
                        break
                    if @nodeList.length is index
                        index = 0
                    if index is @getCountIndex
                        break
                callback null,results
class NodeSession extends rpc.RPCServer
    constructor:(tunnel)->
        super(tunnel)
        console.assert tunnel instanceof rpc.NodeWSTunnel
        @nodeIp = tunnel.ws._socket.remoteAddress
        @date = new Date()
        @declare "getNodes","count"
    close:()->
        @tunnel.close()
    getNodes:(count,callback)->
        console.log "getNode RPC invoke"
        @emit "getNodes",count,callback

server = new Server()