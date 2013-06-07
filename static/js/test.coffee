$ ()->
    factory = new Leaf.ApiFactory()
    factory.path="api/"
    factory.defaultMethod = "GET"
    factory.declare("authedNodes",[]) 
    factory.declare("sendMessage",["guid","message"]) 
    window.API = factory.build()
    window.km = new Leaf.KeyEventManager
    window.km.attachTo window
    window.km.master()
    window.km.on "keydown",(e)->
        if e.which is Leaf.Key.s and e.altKey
            e.capture()
            window.authedNodeList.toggle()
    window.TemplateManager = new Leaf.TemplateManager()
    window.TemplateManager.use "authed-node-list","authed-node-list-item"
    
    window.TemplateManager.on "ready",(templates)->
        window.leafTemplates = templates
        window.authedNodeList = new AuthedNodeList()
        authedNodeList.update()
        authedNodeList.appendTo document.body 
    window.TemplateManager.start()
    window._msgCenter = new MessageCenter(41123)
    window._msgCenter.on "message",(data)->
        alert data.who.pubkey
