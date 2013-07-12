class RssList extends Leaf.Widget
    constructor:()->
        super sybil.templates["rss-list"]
        @items = []
    ListItem:class RssListItem extends Leaf.Widget
        constructor:(data,parent)->
            super(sybil.templates["rss-list-item"])
            @parent = parent
            @init(data);
            @appendTo @parent.UI.listContainer
        init:(data)->
            @data = data
            @UI.name$.text(data.title or "anonymous")
            @UI.count$.text data.unreadCount or 0 
        remove:()->
            super()
            @parent.items = @parent.item.filter (item)=>item!= this
        onClickNode:()->
            sybil.router.goto "/rss/#{@data.id.escapeBase64()}"
            @focus()
        focus:()->
            for item in @parent.items
                item.unfocus()
            @node$.addClass("focus")
        unfocus:()->
            @node$.removeClass("focus")
    addRss:(data)->
        @items.push new RssListItem data,this
    getRssById:(id)->
        for item in @items
            if item.data.id == id
                return item.data
        return null
    sync:()->
        API.rss()
            .success (rsses)=>
                for item in rsses
                    @addRss item
                if not sybil.feedList.currentRss and @items[0]
                    sybil.router.goto "/rss/#{@items[0].data.id.escapeBase64()}"
                                                                                
            .fail (err)->
                console.error err
                console.error "fail to get rss list"
window.RssList = RssList