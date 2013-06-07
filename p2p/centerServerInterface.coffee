rpc = require "../common/rpc.coffee"
centerServerConfig = require "../config/centerServer.coffee"
centerServerPort = centerServerConfig.port
ws = require "ws"
WebSocket = ws
class CenterServerInterface extends rpc.RPCInterface
    constructor:(ip)->
        console.log "ip!",ip
        @ip = ip
        ws = new WebSocket("ws://"+ip+":"+centerServerPort)
        super(new rpc.NodeWSTunnel(ws))
        @declare "getNodes","count"

exports.CenterServerInterface = CenterServerInterface