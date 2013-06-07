# Todo
# 1.Run as an single service
# 2.using Http RPC to interact
# 3.Add hook to server when add rss
# 3.using scheduledFetcher to do the update
db = require "../server/db.coffee"
ScheduledFetcher = (require "./scheduledFetcher.coffee").ScheduledFetcher
RssScheduler = []
db.ready ()->
    rsses = db.Collections.rss.find()
    rsses.toArray (err,arrs)->
        if err
            console.error err
            process.exit(1)
        for rss in arrs
            RssScheduler.push new ScheduledFetcher(rss._id)
            