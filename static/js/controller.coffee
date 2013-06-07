class Controller
    constructor:()->
        @messageCenter = new MessageCenter(41110)
        @messageCenter.on "connect",()->
            $("body").css({"background-color":"green"})
        @messageCenter.on "disconnect",()->
            
            $("body").css({"background-color":"red"})
        $("#nextItem").click ()=>
            console.log "nextItem"
            @messageCenter.send {type:"control",value:"nextItem"} 
        $("#lastItem").click ()=>
            @messageCenter.send {type:"control",value:"lastItem"}
        $("#nextRss").click ()=>
            @messageCenter.send {type:"control",value:"nextRss"}  
        $("#lastRss").click ()=>
            @messageCenter.send {type:"control",value:"lastRss"}
$ ()->
    new Controller()