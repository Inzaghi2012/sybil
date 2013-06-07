RssFetcher = (require "./rssFetcher").RssFetcher
EventEmitter = (require "events").EventEmitter
class ScheduledFetcher extends EventEmitter
    constructor:(url)->
        @url = url
        @rssFetcher = new RssFetcher(@url)
        @nextWait = 
    
    start:()->