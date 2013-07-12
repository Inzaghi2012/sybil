class FeedList extends Leaf.Widget
    constructor:()->
        super(sybil.templates["feed-list"])
        @type = ""
        @count = 20
        @items = []
        @node$.scroll ()=>
            @onScroll()
    goto:(id)->
        rss = sybil.rssList.getRssById(id);
        @clear()
        @UI.title$.text(rss.title)
        @currentRss = rss
        @undrain()
        @more()
    clear:()->
        @items.length = 0;
        @UI.listContainer$.empty()
    ListItem:class FeedListItem extends Leaf.Widget
        constructor:(data)->
            super sybil.templates["feed-list-item"]
            @init data
        init:(data)->
            @UI.title$.text data.title
            @UI.content$.html data.description or ""
            @UI.date$.text moment(data.date).format("L")
            @UI.content$.find("img").each ()->
                # modify relative link
                if this.getAttribute("src").indexOf("http") != 0
                    console.log "resolve"
                    this.setAttribute "src",(sybil.common.resolve data.source,this.getAttribute("src"))
                    console.log "resolved",
    appendFeed:(data)->
        setTimeout (()=>
            feed = new FeedListItem(data)
            feed.appendTo @UI.listContainer
            @items.push feed
        ),0
    onScroll:()->
        
    more:()->
        if @isDrain
            return
        if not @currentRss
            return
        API.feed(@currentRss.source,@count,@items.length,@type)
            .success (data)=>
                if data.drain
                    @drain()
                for item in data.feeds
                    item.rss = @currentRss
                    @appendFeed(item)
            .fail (err)->
                console.error err
                console.error "fail to load feeds",@currentRss.source
    feedInView:(feed)->
    drain:()->
        @isDrain = true
        console.log "ddrain"
    undrain:()->
        @isDrain = false
        console.log "undrain"
        
window.FeedList = FeedList