mongodb = require "mongodb"
require "coffee-script"
express = require "express"
async = require "async"
crypto = require "crypto"
path = require "path"
rpc = require "common-rpc"
settings = require "./settings.coffee"
db = require "../database/db.coffee"
error = require "./error.coffee"
config = require "../config/webServerConfig.coffee"


app = express() 
process.on "uncaughtException",(e)->
    console.error e
    console.trace()
app.enable "trust proxy"
app.use express.bodyParser()
app.use express.cookieParser()
feedServerInterface = rpc.RPCInterface.create({type:"ws",port:config.feedServerPort,host:config.feedServerHost})
# db check ready
app.use (req,res,next)->
    if not db.DatabaseReady
        res.status 503
        res.json {"error":"Server Not Ready"}
        return
    next()
app.use (req,res,next)->
    if not feedServerInterface.tunnel.isReady
        res.status = 504
        res.json ("error":"Feed Server Not Ready")
        return
    next()
# descriptor for json response
app.use error.StandardJsonReply()
app._method = app.get
app._method "/api/subscribe",(req,res)-> 
    source = req.param("source",null)
    if not source
        res.invalidParameter()
        return
    feedServerInterface.addRssFromUrl source,(err,rssInfo)->
        if err
            if err.name is "DuplicatedError"
                res.alreadyExists()
            else
                console.log "err fetch error",err
                res.serverError()
            return
        else
            res.success(rssInfo.feeds)
            return
app._method "/api/unsubscribe",(req,res)->
    source = req.param("source",null)
    if not source
        res.invalidParameter()
        return
    feedServerInterface.removeRssByUrl source
    # remove is a important
    # we don't give feed back
    res.success()
        
app._method "/api/rss",(req,res)->
    db.getAllRsses (err,rsses)->
        if err
            res.serverError()
            return
        res.success(rsses)
        
app._method "/api/feed",(req,res)->
    source = req.param("source",null)
    offset = parseInt(req.param("offset",null))
    type = req.param("type",null)
    count = parseInt(req.param("count",null))
    if not offset
        offset = 0
    if not count
        count = 10
    
    if not source
        res.invalidParameter()
        return
    source = source.trim()
    if type and type.trim() is "all"
        all = true
    else
        all = false
    db.getFeeds {count:count,offset:offset,all:all,source:source},(err,feeds)->
        if err
            res.serverError()
            console.log err
            return
        result = {feeds:feeds}
        if count isnt feeds.length
            result.drain = true
        res.success result
    
app._method "/api/read",(req,res)->
    feed = req.param("id",null)
    if not feed
        res.invalidParameter()
        return
    db.setFeedRead feed,(err,item)->
        res.success()
app._method "/api/unread",(req,res)->
    feed = req.param("id",null)
    if not feed
        res.invalidParameter()
        return
    db.setFeedUnread feed,(err,item)->
        res.success()
app.all "/api/:apiname",(req,res,next)->
    res.status 404
    res.jsonError("Api Not Found",Error.NotFound)

app.get "/*",express.static("/srv/sybil/static/")
app.all "/*",(req,res,next)->
    res.status 404
    res.end "404 :("

app.listen config.port,"0.0.0.0"