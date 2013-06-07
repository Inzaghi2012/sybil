rpc = require "../common/rpc.coffee"
config = require "../config/webServer.coffee"
ws = require "ws"
WebSocket = ws
port = config.localPort
class WebServerInterface extends rpc.RPCInterface
    constructor:()->
        super()
        @declare "sendMessage","authedNode","message"
        @declare "share","info"
        @declare "ping"
        @connect()
    connect:()->
        console.log "connect..."
        ws = new WebSocket("ws://localhost:"+port)
        ws.on "open",()->
            console.log "opend to web server interface",port
        ws.on "error",(err)=>
            console.error err
        @setTunnel new rpc.NodeWSTunnel(ws)
        ws.on "close",()=>
            console.log "local webserver closed"
            console.log "reconnect"
            @connect()
        
exports.WebServerInterface = WebServerInterface