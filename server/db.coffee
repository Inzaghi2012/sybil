mongodb = require "mongodb"
EventEmitter = (require "events").EventEmitter
async = require "async"
ObjectID = (require "mongodb").ObjectID 
settings = (require "./settings").settings
dbServer = mongodb.Server settings.database.host,settings.database.port,settings.database.option
collectionNames = ["rss","feed","like","share"]
dbConnector = new mongodb.Db(settings.database.name,dbServer,{safe:false})
exports.DatabaseReady = false
Collections = {}
exports.Collections = Collections
Database = null
_eventEmitter = new EventEmitter()
dbConnector.open (err,db)->
    if err or not db
        console.error "fail to connect to mongodb"
        console.error err
        process.exit(1)
    dbConnector.db = db
    Database = null
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

exports.ready = (callback)->
    _eventEmitter.on "ready",callback

exports.close = ()->
    dbConnector.close()