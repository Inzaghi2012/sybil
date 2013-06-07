class AuthedNodeList extends Leaf.Widget
    constructor:()->
        super window.leafTemplates["authed-node-list"]
        @isShown = true
        @hide()
    show:()->
        if @isShown
            return
        @isShown = true
        @node$.show()
    hide:()->
        if not @isShown
            return
        @isShown = false
        @node$.hide()
    toggle:()->
        console.error @isShown
        if @isShown
            @hide()
        else
            @show()
    update:(done)->
        call = window.API.authedNodes()
        call.success (data)=> 
            @UI.list$.empty()
            for item in data.data
                li = new AuthedNodeListItem()
                li.init item
                li.appendTo @UI.list
            if typeof done is "function" then done()
window.AuthedNodeList = AuthedNodeList
class AuthedNodeListItem extends Leaf.Widget
    constructor:()->
        super(window.leafTemplates["authed-node-list-item"])
    init:(data)->
        @data = data
        @UI.name$.text(data.pubkey.substring(100,130))
    onClickNode:()->
        message = window.prompt("say something")
        call = API.sendMessage @data.guid.toString(),message
        call.success (data)->
            alert "sent!"