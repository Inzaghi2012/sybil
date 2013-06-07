mongodb = require "mongodb"
require "coffee-script"
express = require "express"
async = require "async"
crypto = require "crypto"
path = require "path"
settings = require "./settings.coffee"
db = require "./db.coffee"
utils = require "./utils.coffee"
error = require "./error.coffee"
rssFetcher = require "../crawler/rssFetcher.coffee"
webServerConfig = require "../config/webServer.coffee"
app = express() 
p2p = require "../p2p/main.coffee"
app.main = p2p.main
p2p.main.app = app
process.on "uncaughtException",(e)->
    console.error e
    console.trace()
#app.p2pLocalInterface = new utils.LocalP2pInterface()
#app.localServer = new (utils.LocalServer)(app)
app.frontWebSocketServer = new utils.FrontWebSocketServer(app)
app.controllerServer = new utils.ControllerServer(app)
app.enable "trust proxy"
app.use express.bodyParser()
app.use express.cookieParser()
# db check ready
app.use (req,res,next)->
    if not db.DatabaseReady
        res.status 503
        res.json {"error":"Server Not Ready"}
        return
    next()
# descriptor for json response
app.use error.StandardJsonReply()
app._method = app.get
app._method "/api/subscribe",(req,res)-> 
    rss = req.param("rss",null)
    if not rss
        res.invalidParameter()
        return
    db.Collections.rss.findOne {_id:rss},(err,item)->
        if err
            console.log "db error",err
            res.serverError()
            return
        if not item
            # fetch and add
            utils.addRss rss,(err,rssInfo)->
                if err
                    console.log "err fetch error",err
                    res.serverError()
                    return
                else
                    res.success(rssInfo)
                    return
        else
            # already exists
            res.alreadyExists()
            return
app._method "/api/unsubscribe",(req,res)->
    rss = req.param("rss",null)
    if not rss
        res.invalidParameter()
        return
    db.Collections.rss.findOne {_id:rss},(err,item)->
        if err
            res.serverError()
            return
        if not item
            res.notFound()
            return
        db.Collections.rss.remove {_id:rss}
        res.success()
        
app._method "/api/rss",(req,res)->
    cursor = db.Collections.rss.find()
    utils.getAllUnreadStatistic (err,unreadData)->
        if err
            res.serverError()
            return
        cursor.toArray (err,rsses)->
            if err
                res.serverError()
                return
            if not rsses
                rsses = []
            
            rssInfos = rsses.map (item)->
                return {id:item._id ,title:item.meta.title or null,date:item.meta.date or null,link:item.meta.link,description:item.meta.description,unreadCount:unreadData[item._id] or 0}
            res.success rssInfos
        
app._method "/api/feed",(req,res)->
    rss = req.param("rss",null)
    start = parseInt(req.param("start",null))
    type = req.param("type",null)
    if not start
        start = 0
    count = parseInt(req.param("count",null))
    if not count
        count = 10
    
    if not rss
        res.invalidParameter()
        return
    rss = rss.trim()
    query = {source:rss}
    
    if type isnt "all"
        query.read = {$exists:false}
        
    cursor = db.Collections.feed.find query,{skip:start,limit:count,sort:"date"}
    
    cursor.toArray (err,arrs)->
        result = {}
        if err
            res.serverError()
            return
        if arrs.length isnt count
            result.drain = true 
        result.feeds = arrs
        db.Collections.feed.find({source:rss,read:{$exists:false}}).count (err,count)->
            if err
                count = 0
            result.unreadCount = count
            res.success result
            return 
    
app._method "/api/read",(req,res)->
    feed = req.param("id",null)
    if not feed
        res.invalidParameter()
        return
    db.Collections.feed.findOne {_id:feed},(err,item)->
        if err
            res.serverError()
            return
        if not item
            res.notFound()
            return
        item.read = true
        db.Collections.feed.update {_id:feed},item
        res.success()
app._method "/api/unread",(req,res)->
    feed = req.param("id",null)
    if not feed
        res.invalidParameter()
        return
    db.Collections.feed.findOne {_id:feed},(err,item)->
        if err
            res.serverError()
            return
        if not item
            res.notFound()
            return
        if item.read
            delete item.read
        db.Collections.feed.update {_id:feed},item
        res.success()
app._method "/api/like",(req,res)->
    feed = req.param("id",null)
    if not feed
        res.invalidParameter()
        return
    db.Collections.feed.findOne {_id:feed},(err,item)->
        if err
            res.serverError()
            return
        if not item
            res.notFound()
            return
        item.like = true
        db.Collections.feed.update {_id:feed},item
        res.success()
app._method "/api/unlike",(req,res)->
    feed = req.param("id",null)
    if not feed
        res.invalidParameter()
        return
    db.Collections.feed.findOne {_id:feed},(err,item)->
        if err
            res.serverError()
            return
        if not item
            res.notFound()
            return
        if item.like
            delete item.like
        db.Collections.feed.update {_id:feed},item
        res.success()

app._method "/api/recommand",(req,res)->
    cursor = db.Collections.share.find()
    cursor.toArray (err,arr)->
        if err
            res.serverError()
            return
        res.success(arr)

app._method "/api/share",(req,res)->
    feed = req.param("id",null)
    if not feed
        res.invalidParameter()
        return
    db.Collections.feed.findOne {_id:feed},(err,item)->
        if err
            console.error "db error"
            res.serverError()
            return
        if not item
            res.notFound()
            return
        app.main.boardCast {type:"share",data:item}
        res.success()
app._method "/api/authedNodes",(req,res)->
    results = app.main.authedNodeList.filter (item)=>
        if item.pubkey is app.main.rsa.publicKey
            return false
        return true 
    res.success {data:results}
app._method "/api/sendMessage",(req,res)->
    guid = req.param("guid",null)
    message = req.param("message",null)
    
    if not guid
        res.invalidParameter()
        return
    if not message
        res.invalidParameter()
        return
    app.main.sendMessage guid,message,(err,result)->
        res.success {err:err,result:result}
app.all "/api/:apiname",(req,res,next)->
    res.status 404
    res.jsonError("Api Not Found",Error.NotFound)

app.get "/*",express.static("/srv/sybil/static/")
app.onMessage = (who,message)->
    console.log "message",who,message
    app.frontWebSocketServer.send {type:"message",value:{who:who,message:message}}
app.onShare = (who,share)->
    console.log "get share",who,share
    share.shareDate = new Date()
    delete share.read
    if not share._id
        share._id = share.source+share.guid
    db.Collections.share.insert share,{safe:true},(err)->
        if err
            console.log "db err"
            return
        console.log "front send share"
        app.frontWebSocketServer.send {type:"share",value:share}
        
            
app.all "/*",(req,res,next)->
    res.status 404
    res.end "404 :("

app.listen webServerConfig.port,"0.0.0.0"

