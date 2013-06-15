rpc = require "../common/rpc.coffee"
RssFetcher = (require "../crawler/rssFetcher.coffee").RssFetcher
db = (require "../database/db.coffee")
ws =  require "ws"
events = require "events"
EventEmitter = events.EventEmitter
exports.getAllUnreadStatistic = (callback)->
    results = {}
    cursor = db.Collections.feed.find {read:{$exists:false}}
    cursor.toArray (err,arrs)->
        if err
            callback err
            return
        for feed in arrs
            if results[feed.source]
                results[feed.source] += 1
            else
                results[feed.source] = 1
        callback null,results
