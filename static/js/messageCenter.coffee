class MessageCenter extends Leaf.EventEmitter 
    constructor:(port)->
        super()
        @port = port
        @connect()
    connect:()->
        
        ws = new WebSocket("ws://"+window.location.hostname+":"+@port)
        ws.onopen = ()=>
            @emit "connect"
        ws.onmessage = (message)=>
            @handleMessage(message.data)
        ws.onclose = ()=>
            @emit "disconnect"
            @connect()
        @ws = ws
    send:(data)->
        @ws.send JSON.stringify(data)
    handleMessage:(msg)->
        try
            data = JSON.parse(msg)
        catch e
            console.log "fail to parse msg",msg
        @dispatch(data)
    dispatch:(data)->
        @emit data.type,data.value
window.MessageCenter = MessageCenter