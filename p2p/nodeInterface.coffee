rpc = require "../common/rpc.coffee"
config = require "../config/p2pnode.coffee"
ws = require "ws"
WebSocket = ws
port = config.port
class NodeInterface extends rpc.RPCInterface
    constructor:(ip)->
        ws = new WebSocket("ws://"+ip+":"+port)
        super(new rpc.NodeWSTunnel(ws))
        @declare "getNodes","count"
        @declare "getPublicKey"
        @declare "autherize","encedData"
        @declare "pushInfo","data"
        @declare "requestAutherize"
exports.NodeInterface = NodeInterface