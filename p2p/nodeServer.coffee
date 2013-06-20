require "../config/nodeServerConfig.coffee"
class NodeServer extends rpc.RPCServer
    constructor:()->
        super new rpc.WebSocketGateway(config.port,config.host)
        @declare "getNodes"
        @declare "getShare"