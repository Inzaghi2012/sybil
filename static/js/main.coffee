class Sybil
  constructor:()->
    console.log 'sybil init'
    @rssArr = []
    @feeds = {}
    @currentPage = 'home'
    window.TemplateManager = new Leaf.TemplateManager()
    window.TemplateManager.use "feed-item-normal","rss-list-item","feeds-list-footer","feeds-list-loading-footer","rss-update-item","authed-node-list","authed-node-list-item"
    
    window.TemplateManager.on "ready",(templates)=>
      window.leafTemplates = templates
      window.authedNodeList = new AuthedNodeList()
      authedNodeList.update()
      authedNodeList.appendTo document.body 
      @apiGet 'rss',null,(err,res)=>
        if err then console.error err
        @initMessageCenter()
        @initButtons()
        @rssArr = res.data
        @initRssList()
        @initFeedsLIst()
        @getFeedsOfAllRss()
    window.TemplateManager.start()
      
  initMessageCenter:()->
    messageCenter = new MessageCenter(41123)
    messageCenter.on "share",(share)=>
      console.log "shared",share
      @showMessage '朋友们分享新文章了'
      $('#recommandPageBtn').addClass "unread"
      $('#recommandPageBtn i').show()
      
    messageCenter.on "control",(action)=>
      console.log "control",action
      @rssList.nextRss() if action is 'nextRss'
      @rssList.lastRss() if action is 'lastRss'
      @feedsList.nextItem() if action is 'nextItem'
      @feedsList.lastItem() if action is 'lastItem'

  initRssList:()->
    @rssList = new RssList(this)
    @rssList.clearAll()
    for rss in @rssArr
      @rssList.addItem rss
    console.log @rssList

  initFeedsLIst:()->
    @feedsList = new FeedsList(this)
    @feedsList.clearAll()
    
  getFeedsOfAllRss:(callback)->
    console.log 'get feeds'
    sum = @rssArr.length
    count = 0
    for rss in @rssArr
      if !rss.start
        rss.start = 0
        rss.count = 10
      console.log rss.id
      if rss.unreadCount is 0
        count += 1
        continue
      @apiGet 'feed',{rss:rss.id,type:'',start:rss.start,count:rss.count},(err,res)=>
        if err then console.error err
        if res.data.feeds and res.data.feeds[0]
          rid = res.data.feeds[0].source
          @feeds[rid] = res.data.feeds if res.data.feeds
          rssObj = do =>
            for r in @rssArr
              if r.id is rid then return r
          console.log @feeds,count
        count += 1
        if count is @rssArr.length
          if typeof callback isnt 'function'
            @showHomePage()
          else callback()
      rss.start += rss.count
    
  getFeedsOfRss:(rss,callback)->
    console.log 'get more feeds'
    @apiGet 'feed',{rss:rss.id,type:'',start:rss.start,count:rss.count},(err,res)=>
      if err then console.error err
      return if res.data.feeds.length is 0
      callback res.data.feeds,res.data.drain if typeof callback is 'function'
    rss.start+=rss.count
      
  showHomePage:()->
    console.log 'show home page /main page'
    @currentPage = 'home'
    @feedsList.showHomePage @rssArr,@feeds
    
  showRecommandedFeeds:()->
    console.log 'show recommanded page'
    $(dom).removeClass 'active' for dom in $ "#rssList .rssListItem"
    $("#recommandPageBtn").removeClass "unread"
    $('#recommandPageBtn i').hide()
    $('#homepageBtn').removeClass 'active'
    $('#recommandPageBtn').addClass 'active'
    @currentPage = 'recommanded'
    @feedsList.showRecommandedFeeds()
    
  showFeedsOfRss:(rss,type = "normal")->
    console.log 'show feeds in rss'
    console.log rss,@feeds[rss.id]
    $('#homepageBtn').removeClass 'active'
    $('#recommandPageBtn').removeClass 'active'
    $("#leftPanel .rssListItem").removeClass 'active'
    listItem =dom for dom in $ "#leftPanel .rssListItem" when dom.rssObj is rss
    $(listItem).addClass "active"
    @currentRss = rss
    @currentPage = 'feeds'
    @feedsList.showFeedsOfRss rss,type
          
  initButtons:()->
    boxJ = $ '#subscribePopup'
    $('#subscribeBtn')[0].onclick = ->
      if boxJ.onshow
        boxJ.fadeOut 'fast'
        boxJ.onshow = false
      else
        boxJ.find("input").val ""
        boxJ.fadeIn 'fast'
        boxJ.onshow = true
    boxJ.find("#applyBtn")[0].onclick = =>
      url = boxJ.find("input")[0].value
      @showMessage '添加中','loading'
      boxJ.fadeOut 'fast'
      @apiGet 'subscribe',{rss:url},(err,res)=>
        if err
          console.error err,res
          @showMessage '添加订阅失败','err'
        else
          @showMessage '添加成功，现在刷新页面','loading'
          @apiGet 'rss',null,(err,res)=>
            @showMessage '完成'
            if err then console.error err
            @initButtons()
            @rssArr = res.data
            @initRssList()
            @getFeedsOfAllRss()
            
    boxJ.find("#cancelBtn")[0].onclick = ->
      boxJ.fadeOut 'fast';
      boxJ.onshow = false;

    $("#homepageBtn")[0].onclick = =>
      @showHomePage()
    $("#recommandPageBtn")[0].onclick = =>
      @showRecommandedFeeds()
      
    $("#refreshBtn")[0].onclick = =>
      @refresh()
      
    $("#markAllReadBtn")[0].onclick = =>
      console.log 'mark all read btn clicked'
      for rss in @rssArr
        for feed in @feeds[rss.id]
          @feedsList.markFeedAsRead feed,rss
      
  refresh:()->
    console.log 'refresh!'
    if @currentRss
      nowRssId = @currentRss.id
    @showMessage '正在刷新','loading'
    @apiGet 'rss',null,(err,res)=>
      if err
        @showMessage '刷新失败','err'
        console.error err
        return
      @showMessage '完成'
      @initButtons()
      @rssArr = res.data
      @initRssList()
      @getFeedsOfAllRss =>
        return if !nowRssId
        for rssObj in @rssArr
          if rssObj.id is nowRssId
            @showFeedsOfRss rssObj
            break
  
  initFeedItemButtons:(J)->
    console.error "error! init feeditem button method has been move to feedsList.coffee"
    
  apiGet:(type,data,callback)->
    console.log "api.get!","/api/"+type,data
    req = $.get "/api/"+type,data,(res,status,xhr)->
      console.log 'ajax request successed',res
      callback res.error,res
    req.fail (err)=>
      @showMessage '网络错误','err'
      callback err
  
  showMessage:(msg,type='normal')->
    if !@msgBox
      @msgBox = $ "#messageBox"
      @msgBox.onshow = false
      @msgBox.lastMsg = null
    p = @msgBox.find "p"
    @msgBox.fadeIn 'fast'
    p.fadeOut 'fast',=>
      p.html msg
      if type is 'error' then p.addClass 'error'
      else p.removeClass 'error'
      spinner = @msgBox.find("#spinner")
      if type is 'loading' then spinner.show()
      else spinner.hide()
      if type isnt 'loading'
        @msgBox.lastMsg = msg
        window.setTimeout (=>
          if @msgBox.lastMsg is msg then @msgBox.fadeOut 'fast'
          ),1000
      p.fadeIn 'fast'
      
window.onload = ()->
  sybil = new Sybil
