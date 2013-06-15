RssFetcher = (require "./rssFetcher").RssFetcher
EventEmitter = (require "events").EventEmitter
class ScheduledFetcher extends EventEmitter
    constructor:(url)->
        @url = url
        @rssFetcher = new RssFetcher(@url)
        @lastUpdate = 0
        @lastTryUpdate = 0
        @maxUpdateInterval = 1000 * 60 *60 * 3 # 3 hours
        @minUpdateInterval = 1000 * 60 *1 *0.2 # 1 min
        @increaseFactor = 2
        @interval = @minUpdateInterval
        @start()
    suggestUpdate:()->
        @_update()
    _update:(callback)->
        
        @rssFetcher.update (err,data)=>
            @lastTryUpdate = Date.now()
            if err
                console.error "fail to update rss",@url,err
                @interval *= @increaseFactor
            else
                lastUpdate = data.meta.date or new Date()
                # some situation is not considered such as
                # rss feed no t output  date or output wrong date
                if lastUpdate.getTime() isnt @lastUpdate
                    # has updated
                    @interval = @minUpdateInterval
                    @lastUpdate =lastUpdate.getTime()
                    console.log "updated"
                    @emit "update"
                else
                    console.log "not updated",@url
                    @interval *= @increaseFactor
            @interval >= @maxUpdateInterval
            @interval = @maxUpdateInterval
            if typeof callback is "function"
                callback()
    start:()->
        @_update()
        setInterval (()=>
            console.log @lastTryUpdate,@interval,@lastTryUpdate+@interval,Date.now()
            if @lastTryUpdate+@interval < Date.now()
                @_update()
            ),@minUpdateInterval/2
exports.ScheduledFetcher = ScheduledFetcher