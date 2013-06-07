ws = require "ws"
WebSocket = ws
WebSocketServer = ws.Server
rsaModule = require "../common/rsa.coffee"

centerServer = "localhost"
rpc = require "../common/rpc.coffee"
centerServerConfig = require "../config/centerServer.coffee"
p2pnodeConfig = require "../config/p2pnode.coffee"
events = require "events"
EventEmitter = events.EventEmitter
EasySettings = (require "easysettings").EasySettings;
ES = new EasySettings("p2pdata.conf.json")
centerServerIp = centerServerConfig.ip
centerServerPort = centerServerConfig.port
nodePort = p2pnodeConfig.port
localPort = p2pnodeConfig.localPort 
LocalSession = (require "./localSession.coffee").LocalSession
PublicSession = (require "./publicSession.coffee").PublicSession
CenterServerInterface = (require "./centerServerInterface.coffee").CenterServerInterface
NodeInterface = (require "./nodeInterface.coffee").NodeInterface;
WebServerInterface = (require "./webServerInterface").WebServerInterface
__guid = 1

createGuid = ()->
    return __guid++;
class PublicServer extends EventEmitter
    constructor:(rsa,main)-> 
        @server = new WebSocketServer({port:nodePort,host:"0.0.0.0"})
        @main = main
        @sessionList = []
        @maxNodeCountReturn = 50
        @getCountIndex = 0
        @rsa = rsa
        @_buildRSA ()=>
            @_buildServer()
    _buildRSA:(callback)->
        if @rsa and @rsa.publicKey and @rsa.privateKey
            @publicKey = @rsa.publicKey
            @privateKey = @rsa.privateKey
            if typeof callback is "function"
                callback()
        else
            @rsa = {}
            rsaModule.generatePrivateKey (err,key)=>
                if err
                    console.error "fail to generate rsa private key"
                    throw err
                @rsa.privateKey = key.toString()
                rsaModule.generatePublicKey @rsa.privateKey,(err,key)=>
                    if err
                        console.error "fail to generate rsa public key"
                        throw err
                    @rsa.publicKey = key
                    
                    @publicKey = @rsa.publicKey
                    @privateKey = @rsa.privateKey
                    @emit "rsaChange"
                    if typeof callback is "function"
                        callback()
                    callback()
    _buildServer:()->
        @server.on "connection",(ws)=>
            useIt = false
            session = new PublicSession(new rpc.NodeWSTunnel(ws),this,this.main)
            for item,index in @sessionList
                if item.nodeIp is session.nodeIp
                    @sessionList.splice index,1
                    @sessionList.push session
                    useIt = true
                    break
            if not useIt
                @sessionList.push session
    getNodes:(count)->
            if count > @maxNodeCountReturn
                count = @maxNodeCountReturn
            if @sessionList.length is 0
                callback(null,[])
            index = @getCountIndex
            results = []
            
            while true
                while @sessionList.length > index
                    results.push @sessionList[index].nodeIp
                    if results.length >= count
                        break
                    index++
                    if index is @getCountIndex
                        break
                if results.length >= count
                    break
                if @sessionList.length is index
                    index = 0
                if index is @getCountIndex
                    break
            return results
                

class Main
    constructor:()->
        @localServer = new WebSocketServer({host:"localhost",port:localPort})
        console.log "server localport",localPort
        @localServer.on "connection",(ws)=>
            new LocalSession(new rpc.NodeWSTunnel(ws),this)
#        @webServerInterface = new WebServerInterface()
#        @webServerInterface.ping (err,data)->
#            console.log "ping",err,data
        @configDatas = ES.load()
        @centerServer = new CenterServerInterface(centerServerIp)
        @centerServer.on "close",()=>
            console.warn "connection to center server is closed"
            console.log "reopen"
            @centerServer = new CenterServerInterface(centerServerIp)
        @rsa = @configDatas.rsa
        @publicServer = new PublicServer(@configDatas.rsa,this)
        @publicServer.on "rsaChange",()=>
            @save()
            @rsa = @publicServer.rsa
        @buildNodes()
        @maintainInterval = 1000 * 5
        
        setInterval (()=>
            @maintainNodeLinks()
#            console.log "currentNodes",@nodeList
#            console.log "authedNodes":@authedNodeList
            ),@maintainInterval
    sayHelloToCenterServer:()->
        # this is just like say hello ...
        @getMoreNodes()
    sendMessage:(guid,message,callback)->
        for item in @authedNodeList
            if item.guid.toString() is guid
                inf = new NodeInterface(item.ips[0])
                inf.pushInfo {type:"message",data:message}
                console.log "sent"
                callback null
                return
        console.log "fail to sent"
        callback new Error "invalid guid"
        return
    buildNodes:()->
        @knownNodes = @configDatas.knownNodes or []
        @nodeList = @configDatas.nodeList or []
        @authedNodeList = []
        @maintainNodeLinks()
    maintainNodeLinks:()->
        @getMoreNodes()
        @linkNodes()
    linkNodes:()->
        for ip in @nodeList
            authed = false
            for item in @authedNodeList
                if item.ips and ip in item.ips
                    authed = true
                    break
            if authed
                continue
            @autherizeNode(ip)
            
    saveNodes:()->
        @configDatas.knownNodes = @knownNodes
        @configDatas.nodeList = @nodeList
    save:()->
        @saveNodes()
        @configDatas.rsa = @publicServer.rsa
        ES.save()
    getMoreNodes:()->
        #getMoreNodes from center server 
        @centerServer.getNodes 100,(err,nodes)=>
            console.log "more nodes",nodes.length
            if err
                console.log "center server error",err
                return
            
            for ip in nodes
                if ip not in @nodeList
                    @nodeList.push ip
    boardCast:(info)->
        for node in @authedNodeList
            ip = node.ips[node.ips.length-1]
            if not ip
                continue
            if node.pubkey is @rsa.publicKey
                #"skip your self"
                continue
            inf = new NodeInterface(ip)
            inf.pushInfo info
    addAuthedNode:(ip,pubkey)->
        for item in @authedNodeList
            if item.pubkey is pubkey
                item.ips = [ip]
                return
        notKnow = true
        for item in @knownNodes
            
            if item.pubkey is pubkey
                item.ips = item.ips or []
                item.ips.push ip
                notKnow = false
        if notKnow
            @knownNodes.push {ips:[ip],pubkey:pubkey}
        info = {pubkey:pubkey,ips:[ip],guid:createGuid()} 
        @authedNodeList.push info
        @knownNodes.push info
    getAuthedNodeByIp:(ip)->
        for item in @authedNodeList
            if ip in item.ips
                return item
        return null
    autherizeNode:(ip)->
        if @getAuthedNodeByIp(ip)
            return true
        
        console.log "autherizeNode:ip",ip
        nodeInterface = new NodeInterface(ip)

        # nodeInterface.requestAutherize (err)->
        # console.log "requestAutherize",err
        nodeInterface.getPublicKey (err,pubkey)=>
            if err
                console.error "fail to get pubkey",err
                return
            rawToken = (Math.random()).toString()
            rsaModule.encrypt new Buffer(rawToken),pubkey,(err,data)=>
                if err
                    console.error "fail to enc rawToken"
                    return
                nodeInterface.autherize data.toString("base64"),(err,result)=>
                    if err
                        console.log "fail to remove autherize"
                        return
                    returnToken = new Buffer(result,"base64").toString()
                    
                    if returnToken isnt rawToken
                        console.log "sign failed"
                        return
                    @addAuthedNode ip,pubkey
                        
exports.main = new Main()