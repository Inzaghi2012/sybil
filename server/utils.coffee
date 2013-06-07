rpc = require "../common/rpc.coffee"
RssFetcher = (require "../crawler/rssFetcher.coffee").RssFetcher
db = (require "./db.coffee")
ws =  require "ws"
WebSocket = ws
WebSocketServer = ws.Server
webServerConfig = require "../config/webServer.coffee"
p2pConfig = require "../config/p2pnode.coffee"
events = require "events"
EventEmitter = events.EventEmitter
p2pLocalPort = p2pConfig.localPort
exports.addRss = (url,callback)->
    url = url.trim()
    if not db.DatabaseReady
        console.error "database not ready"
        console.trace()
        callback new Error "database not ready"
        return 
    fetcher = new RssFetcher url
    fetcher.update (err,info)->
        if err
            callback err
            return
        db.Collections.rss.insert {_id:url,meta:info.meta},{safe:true},(err)->
            if err
                console.error "fatal db error"
                callback err
                return
            callback null,info
exports.getAllUnreadStatistic = (callback)->
    results = {}
    cursor = db.Collections.feed.find {read:{$exists:false}}
    cursor.toArray (err,arrs)->
        if err
            callback err
            return
        for feed in arrs
            if results[feed.source]
                results[feed.source] += 1
            else
                results[feed.source] = 1
        callback null,results

class LocalP2pInterface extends rpc.RPCInterface
    constructor:()->
        super()
        @declare "sendMessage","guid","content"
        @declare "share","info"
        @declare "getAuthedNodes"
        @connect()
    connect:()->
        ws = new WebSocket("ws://localhost:"+p2pLocalPort+"/")
        console.log "p2pLocalPort",p2pLocalPort
        @setTunnel new (rpc.NodeWSTunnel)(ws)
        ws.on "error",(err)->
            console.error err,"p2p interface error" 
        ws.on "close",()=>
            console.log "local p2p interface closed"
            console.log "reconnect"
            @connect()
exports.LocalP2pInterface = LocalP2pInterface

class LocalServer extends rpc.RPCServer
    constructor:(app)->
        super()
        @app = app
        console.log "localserver port",webServerConfig.localPort
        @server = new WebSocketServer({host:"localhost",port:webServerConfig.localPort})
        @server.on "connection",(ws)=>
            console.log "local server connection"
            ws.on "error",(err)->
                console.log "error??",err
            ws.on "close",()->
                console.log "opend close"
            @setTunnel(ws)
        @declare "sendMessage","authedNode","message"
        @declare "share","info"
        @declare "ping"
    sendMessage:(authedNodeInfo,message,callback)->
        console.log "message",message,"from",authedNodeInfo
    ping:(callback)->
        console.log "I'm Pinged"
        callback null,true
exports.LocalServer = LocalServer
class ControllerServer extends EventEmitter
    constructor:(app)->
        @app = app
        @server = new WebSocketServer {host:"0.0.0.0",port:41110}
        @server.on "connection",(ws)=>
            @build(ws)
    build:(ws)->
        ws.on "message",(data)=>
            try
                json = JSON.parse(data)
            catch e
                return
            console.log "getJson",json
            @app.frontWebSocketServer.send json
exports.ControllerServer = ControllerServer
class FrontWebSocketServer extends EventEmitter
    constructor:()->
        @server = new WebSocketServer {host:"0.0.0.0",port:webServerConfig.frontWebSocketPort}
        @server.on "connection",(ws)=>
            console.log "connection1"
            @build(ws)
        @clients = []
    build:(ws)->
        @clients.push ws
        ws.on "close",()=>
            index = @clients.indexOf(ws)
            if index < 0
                return
            @clients.splice(index,1)
        ws.on "error",()=>
            return
        ws.on "message",(message)=>
            @emit "message",message
    send:(data)->
        
        for client in @clients
            try
                client.send(JSON.stringify(data))
            catch e
                console.log e
                # pass
exports.FrontWebSocketServer = FrontWebSocketServer
