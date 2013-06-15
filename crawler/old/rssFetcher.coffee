request = require "request"
feedparser = require "feedparser"
db = require "../server/db.coffee"
async = require "async"
class RssFetcher
    constructor:(url)->
        @url = url
    fetch:(callback)->
        try
            parser = feedparser.parseUrl(@url)
            parser.on "error",(err)->
                callback err,null
            parser.on "complete",(meta,articles)=>
                info={meta:meta,articles:articles}
                results = []
                for article in info.articles
                    if not article
                        continue
                    results.push {title:article.title,link:article.link,source:@url,author:article.author,date:article.date,guid:article.guid,id:@url+article.guid,summary:article.summary or article.title,description:article.description or article.title}
                info.articles = results
                callback(null,info)
        catch e
            callback e
    update:(callback)->
        if not db.DatabaseReady
            callback new Error "Database not ready"
            return
        @fetch (err,info)=>
            if err
                callback(err)
                return
            # Note just insert without see it feed exists
            # may cause unforseen some problem
            inserted = []
            async.forEach info.articles,((item,done)->
                item._id = item.id 
                db.Collections.feed.insert item,{safe:true},(err)->
                    delete item._id
                    if err
                        if err.code is 11000 #duplicated key error
                            inserted.push item
                        done err
                        return
                    inserted.push item
                    done null
                ),(err)=>
                    if err and err.code isnt 11000 # duplicated key
                        callback err
                        return
                    callback null,info
exports.RssFetcher = RssFetcher