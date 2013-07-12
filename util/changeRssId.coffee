fs = require "fs"
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
    db.collection "feed",(err,col)->
        cursor = col.find()
        cursor.toArray (err,arr)->
            for feed in arr
                _id = feed._id
                feed._id = toBase64(feed.source+feed.guid)
                feed.id = toBase64(feed.source+feed.guid)
                col.remove {_id:_id},{safe:true},(err)->
                    if err
                        console.error err
                        process.exit(0)
                    col.insert feed,{safe:true},(err)->
                        if err and  err.code == 11000
                            return
                        if err
                            console.error err
                            process.exit(0)
                        console.log "change feed to",feed._id