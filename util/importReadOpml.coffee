config = require "../config/webServerConfig.coffee"
xml2js = require "xml2js"
fs = require "fs"
async = require "async"
rpc = require "common-rpc"
filePath = process.argv[2]
if not filePath
    console.log "usage coffee importReadOpml.coffee <subscription.xml path>"
    process.exit(1)
xml =  (fs.readFileSync filePath).toString()    
rsses = []
xml2js.parseString xml,(err,json)->
    items = json.opml.body[0].outline
    for item in items
        info = item.$
        if info.type is "rss"
            console.log info.xmlUrl
            rsses.push info.xmlUrl
        else
            console.log "folder",info.title
            indent = "   "
            for _item in item.outline
                console.log indent,_item.$.xmlUrl
                rsses.push _item.$.xmlUrl
    console.log "RSSES"
    console.log rsses
    fails = []
    rpc.RPCInterface.create {type:"ws",port:config.feedServerPort,host:config.feedServerHost,autoConfig:true},(err,inf)->
        inf.timeout = 1000 * 60
        if err
            console.error err
            console.error err.stack
            console.error "fail to connect to feed server"
            process.exit(1)
        async.forEachLimit rsses,10
            ,(rss,done)->
                inf.addRssFromUrl rss,(err,result)->
                    if err
                        console.log "fail to add rss",rss
                        console.error err
                        done null
                        fails.push {err:err,rss:rss}
                        return
                    console.log rss,"feeds count",result.feeds.length
                    done()
            ,(err,result)->
                for item in fails
                    console.log "rss",item.rss,"failed for",item.err
                if err
                    console.error err
                    process.exit(1)
                    return
                else
                    console.log "success"
                    inf.close()
                    
            
