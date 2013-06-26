feedparser = require "feedparser"
config = require "../config/feedServerConfig.coffee"
rpc = require "common-rpc"
RPCServer = rpc.RPCServer
request = require "request"
db = require "../database/db.coffee"
async = require "async"
events = require "events"
class RssFetcher extends events.EventEmitter
    constructor:(url)->
        super()
        @url = url
    checkFeedValidation:(feed)->
        # return false on cases that broken dbs
        if not feed.guid
            return false
        return true
    fetch:(callback)->
        try
            meta = null
            articles = []
            parser = reqeust(@url).pipe(new feedparser())
            parser.on "readable",()->
                while article = parser.read()
                    articles.push article
            parser.on "error",(err)->
                callback err,null
            parser.on "end",()=>
                @rssInfo = {
                    rssUrl:@url
                    ,title:meta.title or null
                    ,descriptor:meta.descriptor or null
                    ,link:meta.link or null
                    ,author:meta.author or null
                    ,language:meta.language or null
                    ,favicon:meta.favicon or null
                    ,date:meta.date or null
                }
                results = []
                for article in articles
                    if not article
                        continue
                    
                    feed = {
                        title:article.title or null
                        ,link:article.link or null
                        ,source:@url 
                        ,author:article.author or null
                        ,date:article.date or null
                        ,guid:article.guid or null
                        ,id:@url+article.guid
                        ,summary:article.summary or null
                        ,description:article.description or null
                        }
                    if @checkFeedValidation(feed)
                        results.push feed
                    else
                        callback new Error "Invalid Feed"
                        return
                info = {}
                # garenteed to sort by date
                results.sort (a,b)->
                    valueA = a.date and a.date.getTime() or 0
                    valueB = b.date and b.date.getTime() or 0
                    # from latest (bigest time) to earlier (smaller time)
                    return valueB - valueA
                info.feeds = results
                info.rss = @rssInfo
                callback(null,info)
        catch e
            callback e
class ScheduledFetcher extends RssFetcher
    constructor:(url)->
        super(url)
        @feeds = []
        @timer = null
        @minFetchInterval = 1000 * 60 * 1
        @timeFactor = 4
        @currentInterval = @minFetchInterval

    start:()->
        @checkout()
    stop:()->
        if @timer
            clearTimeout(@timer)
            @timer = null
    checkout:()->
        console.log "checkout #{@url}"
        @fetch (err,info)=>
            if err
                @emit "error",err
                return
            console.log "checkout fetched #{@url}",info.feeds and info.feeds.length or "no feeds"
            # whatever update the rss meta info first
            @rss = info.rss
            newFeeds = @_pickUpdateFeeds(info.feeds)
            if newFeeds
                # though newFeeds is not reliablely new
                # but we won't miss anything.
                # Emit newFeeds not @feeds,
                # to reduce the check works of upper modules
                @feeds = info.feeds
                @emit "update",newFeeds
   
            meantime = @meanFeedPublishInterval()
            console.log "mean update time #{@url}:#{meantime}"
            minInterval = @minFetchInterval
            if meantime > minInterval
                maxInterval = meantime
            else
                maxInterval = minInterval 
            if newFeeds
                # is updated use the minInterval
                @_setNextCheckoutSchedule(minInterval)
                console.log "#{@url} has update #{newFeeds.length}"
            else
                interval = Math.min(maxInterval,@currentInterval*@timeFactor)
                @_setNextCheckoutSchedule(interval)
                console.log "#{@url} has no update" 
    _setNextCheckoutSchedule:(interval)->
        if @timer
            clearTimeout(@timer)
        @currentInterval = interval
        console.log "nextInterval #{@url} #{interval}"
        @timer = setTimeout (@checkout.bind this),interval
    meanFeedPublishInterval:()->
        intervals = []
        for cursor in [0...@feeds.length-1]
            first = @feeds[cursor].date and @feeds[cursor].date.getTime() or 0
            second = @feeds[cursor+1].date and @feeds[cursor+1].date.getTime() or 0
            return first - second
        total = intervals.reduce (a,b)->
            a+b
        return total/intervals.length
            
    _pickUpdateFeeds:(feeds)->
        # pickUpdateFeeds method is important
        # It will be used to determin next update time,
        # if there are some feed picked out as the new,
        # and notify other module about the rss updation.
        # There are many ways to perform the check
        # 1.Sort the latest downloaded feed by date
        # compare the current fetching's latest feed, If the date matches It's updated
        # Pros: easy,fast(?)
        # Cons: broken when rss don't output latest RSS,and wont be able to inform
        # other modules what's updated. and date may be equal, since feed date is not
        # that corrent,this is buggy.And when 2 latest article has the same date, the check may fail
        # and the check logic is complicated.And may be buggy.
        # 2.Compare all the guid, If there are some feed in the current fetching
        # but not appears in the last fetching than it's updated
        # Pros: able to inform what's updated (though maybe incorrect on first fetching)
        # So it's actually not that useful,since it's not garenteed and not reliable
        # Cons: a little bit slow, and unable to parse when feed
        # not output guid(unlike to happen)
        # 3. Use method 1 to notify update but method 2 to check what updated
        # Method 1 is buggy. Buggy one plus normal one give an even buggy one. This idea is silly.
        newFeeds = []
        for feed in feeds
            isOld = false
            for oldFeed in @feeds
                if feed.guid is oldFeed.guid
                    isOld = true
                    # Rss is broken one
                    # 
                    if not feed.guid
                        console.warn "broken rss",@url
                        @brokenRss = true
                    break
            if not isOld
                newFeeds.push feed
        if newFeeds.length > 0 
            # we can't differ new feeds from actually
            # the old one when we first fecthing. We just leave
            # it to other modules(with db access) to do so.
            # Thought the newFeeds is not reliablaly new,
            # but we won't miss anything.
            return newFeeds
        return null

class FeedServer extends RPCServer
    constructor:()->
        @host = config.host or "localhost"
        @port = config.port or 63001
        super(new rpc.WebSocketGateway(@port,@host))
        @declare("addRssFromUrl")
        @declare("removeRssByUrl")
        @init()
    init:()->
        # 1.load user rss from db
        # 2.according to the rss loaded, start timer for each rss
        # 3.start RPCServer for adding/fetching new Rss
        console.assert db.DatabaseReady
        # load user rsses 
        cursor = db.Collections.rss.find {}
        cursor.toArray (err,rsses)=>
            if err
                console.error err
                console.error "fatal error fail to load rsses from db"
                return
            console.log "setups"
            @_setupRssSchedule(rsses)
    _setupRssSchedule:(rsses)->
        @schedules = []
        for rss in rsses
            console.log rss
            @watchRss(rss.source)
    watchRss:(rssUrl)->
        fetcher = new ScheduledFetcher(rssUrl)
        @schedules.push fetcher
        fetcher.start()
        fetcher.on "error",(err)=>
            # has nothing todo yet
            console.error "Scheduale Rss Fetcher Error",err
        fetcher.on "update",(feeds)=>
            db.insertFeeds(feeds)
    removeRssByUrl:(url,callback)->
        for schedule,index in @schedules
            if schedule.url is url
                @schedules.splice(index,1)
                db.removeRss(url)
                break;
        
        if callback then callback()
    addRssFromUrl:(url,callback)-> 
        fetcher = new RssFetcher(url)
        fetcher.fetch (err,info)=>
            if err
                callback err
                return
            rss = info.rss
            rssInfo = {
                title:rss.title or null
                ,description:rss.description or null
                ,link:rss.link or null
                ,auther:rss.auther or null
                ,source:url
                ,language:rss.language or null
                ,favicon:rss.favicon or null
            }
            db.addRss rssInfo,(err)=>
                if err
                    if err.name is "DuplicatedError"
                        callback null,{duplicate:true,feeds:info.feeds,rss:info.rss}
                    else
                        callback err
                    return 
                callback null,{feeds:info.feed,rss:info.rss}
                console.log "new rss #{url} added,watch it"
                @watchRss url
    

exports.RssFetcher = RssFetcher
process.cleanUp = ()->
    rpc.Gateway.clear()
    db.close()
process.safeExit = (code)->
    @cleanUp()
    @exit(code)
process.on "SIGTERM",process.safeExit.bind(process)
process.on "SIGINT",process.safeExit.bind(process)
main = ()->
    console.log "connect to db..."
    db.ready ()->
        console.log "start feed server..."
        feedServer = new FeedServer()
        feedServer.on "ready",()->
            console.log "feed server ready"
    
main()