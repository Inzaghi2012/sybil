window.exports = {}
String.prototype.escapeBase64 = ()->
    return this.replace(/\//,"*")
String.prototype.unescapeBase64 = ()->
    return this.replace(/\*/,"/")
$ ->
    window.sybil = new Sybil;

class Sybil extends Leaf.Widget
    constructor:()->
        @rssArr = []
        @feeds = {}
        window.TemplateManager = new Leaf.TemplateManager()
        window.TemplateManager.use "rss-list","rss-list-item","feed-list","feed-list-item"
        window.TemplateManager.on "ready",(templates)=>
            @templates = templates
            @init()
            super(document.body)
            console.log @rssList.node
        window.TemplateManager.start()
    init:()->
        @router = new Router()
        @rssList = new RssList()
        @feedList = new FeedList()
        @rssList.sync()
        @router.goto window.location.hash
        @common = exports