mongodb = require "mongodb"
EventEmitter = (require "events").EventEmitter
async = require "async"
ObjectID = (require "mongodb").ObjectID 
config = (require "../config/databaseConfig.coffee")
dbServer = mongodb.Server config.host,config.port,config.option
collectionNames = ["rss","feed","like","share"]
dbConnector = new mongodb.Db(config.name,dbServer,{safe:false})
exports.DatabaseReady = false
Collections = {}
exports.Collections = Collections
_eventEmitter = new EventEmitter()
toBase64 = (string)->
    return new Buffer(string).toString("base64")
dbConnector.open (err,db)->
    if err or not db
        console.error "fail to connect to mongodb"
        console.error err
        process.exit(1)
    dbConnector.db = db
    async.map collectionNames,((collectionName,callback)->
        dbConnector.db.collection(collectionName,(err,col)->
            if err
                callback err
            else
                callback null,col
                
            )
        return true),
        (err,results)->
            if err
                console.error "fail to prefetch Collections"
                process.exit(1)
                return
            for name,index in collectionNames
                Collections[name] = results[index]
            exports.DatabaseReady = true
            _eventEmitter.emit "ready"
exports.setFeedRead = (id,callback)->
    Collections.feed.findAndModify {_id:id,read:false},{$set:{read:true}},{safe:true},(err,obj)->
        # change the total read count
        if obj
            Collections.rss.update {_id:obj._id},{$inc:{unread:1}}
        if callback
            callback()
exports.setFeedUnread = (id,callback)->
    Collections.feed.findAndModify {_id:id,read:true},{$set:{read:false}},{safe:true},(err,obj)->
        # change the total read count
        if obj
            Collections.rss.update {_id:obj._id},{$inc:{unread:-1}}
        
exports.insertFeeds = (feeds,callback)->
    if not feeds and callback
        callback null
        return
    if not (feeds instanceof Array) and callback
        callback new Error "insert feeds need array"
        return
    # mongodb is just a temperory choice
    # thus not that much error handleing
    for feed in feeds
        feed._id = toBase64(feed.source+feed.guid)
        feed.read = false
        Collections.feed.insert feed,{safe:true},(err)->
            if err and err.code is 11000
                # duplicated is tolerented
                return
            if err
                console.error "db error",err
                return
            # tolerence if _id not exists
            # so dont check it
            Collections.rss.update {source:feed.source},{$inc:{unreadCount:1}}
    if callback 
        callback null
exports.ready = (callback)->
    _eventEmitter.on "ready",callback
    
exports.addRss = (rss,callback)->
    rss._id = toBase64 rss.source
    Collections.rss.insert rss,{safe:true},(err,data)->
        if err
            if err.code is 11000
                cbError = new Error "duplicate rss"
                cbError.name = "DuplicatedError"
                callback cbError
                return
            else
                callback err
                return
        callback null
exports.removeRss = (id,callback)->
    Collections.rss.remove {_id:id},{safe:true},(err)->
        if not callback
            return
        if err
            callback err
            return
        callback null
exports.getAllRsses = (callback)->
    cursor = Collections.rss.find()
    cursor.toArray (err,arr)->
        for item in arr
            item.id = item._id
            delete item._id
        if err
            callback err
            return
        callback null,arr
exports.getFeeds = (info,callback)->
    if not callback
        return
    count = info.count or 15
    offset = info.offset or 0
    all = info.all or false
    source = info.source
    if not source
        callback new Error "Invalid Source"
        return
    query = {source:source}
    if not all
        query.read = false
    
    
    cursor = Collections.feed.find query,{skip:offset,limit:count,sort:{"date":-1}}
    cursor.toArray (err,arrs)->
        if err
            callback err
            return
        for item in arrs
            item.id = item._id
            delete item._id
        callback null,arrs
            
    
exports.close = ()->
    dbConnector.close()








