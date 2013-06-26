class Sybil
  constructor:()->
    console.log 'sybil init'
    @sourceArr = []
    @feeds = {}
    @currentPage = 'home'
    window.TemplateManager = new Leaf.TemplateManager()
    window.TemplateManager.use "feed-item-normal","source-list-item","feeds-list-footer","feeds-list-loading-footer","source-update-item","authed-node-list","authed-node-list-item"
    
    window.TemplateManager.on "ready",(templates)=>
      window.leafTemplates = templates
      window.authedNodeList = new AuthedNodeList()
      authedNodeList.update()
      authedNodeList.appendTo document.body 
      @apiGet 'source',null,(err,res)=>
        if err then console.error err
        @initButtons()
        @sourceArr = res.data
        source.id = source.source for source in @sourceArr
        @initSourceList()
        @initFeedsLIst()
        @getFeedsOfAllSource()
    window.TemplateManager.start()
    
  initSourceList:()->
    @sourceList = new SourceList(this)
    @sourceList.clearAll()
    for source in @sourceArr
      @sourceList.addItem source
    console.log @sourceList

  initFeedsLIst:()->
    @feedsList = new FeedsList(this)
    @feedsList.clearAll()
    
  getFeedsOfAllSource:(callback)->
    console.log 'get feeds'
    sum = @sourceArr.length
    count = 0
    for source in @sourceArr
      if !source.offset
        source.offset = 0
        source.count = 10
      console.log source.id
      if source.unreadCount is 0
        count += 1
        continue
      @apiGet 'feed',{source:source.id,type:'',offset:source.offset,count:source.count},(err,res)=>
        if err then console.error err
        if res.data.feeds and res.data.feeds[0]
          rid = res.data.feeds[0].source
          @feeds[rid] = res.data.feeds if res.data.feeds
          sourceObj = do =>
            for r in @sourceArr
              if r.id is rid then return r
          console.log @feeds,count
        count += 1
        if count is @sourceArr.length
          if typeof callback isnt 'function'
            @showHomePage()
          else callback()
      source.offset += source.count
    
  getFeedsOfSource:(source,callback)->
    console.log 'get more feeds'
    @apiGet 'feed',{source:source.id,type:'',offset:source.offset,count:source.count},(err,res)=>
      if err then console.error err
      return if res.data.feeds.length is 0
      callback res.data.feeds,res.data.drain if typeof callback is 'function'
    source.offset+=source.count
      
  showHomePage:()->
    console.log 'show home page /main page'
    @currentPage = 'home'
    @feedsList.showHomePage @sourceArr,@feeds
    
  showRecommandedFeeds:()->
    console.log 'show recommanded page'
    $(dom).removeClass 'active' for dom in $ "#sourceList .sourceListItem"
    $("#recommandPageBtn").removeClass "unread"
    $('#recommandPageBtn i').hide()
    $('#homepageBtn').removeClass 'active'
    $('#recommandPageBtn').addClass 'active'
    @currentPage = 'recommanded'
    @feedsList.showRecommandedFeeds()
    
  showFeedsOfSource:(source,type = "normal")->
    console.log 'show feeds in source'
    console.log source,@feeds[source.id]
    $('#homepageBtn').removeClass 'active'
    $('#recommandPageBtn').removeClass 'active'
    $("#leftPanel .sourceListItem").removeClass 'active'
    listItem =dom for dom in $ "#leftPanel .sourceListItem" when dom.sourceObj is source
    $(listItem).addClass "active"
    @currentSource = source
    @currentPage = 'feeds'
    @feedsList.showFeedsOfSource source,type
          
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
      @apiGet 'subscribe',{source:url},(err,res)=>
        if err
          console.error err,res
          @showMessage '添加订阅失败','err'
        else
          @showMessage '添加成功，现在刷新页面','loading'
          @apiGet 'source',null,(err,res)=>
            @showMessage '完成'
            if err then console.error err
            @initButtons()
            @sourceArr = res.data
            @initSourceList()
            @getFeedsOfAllSource()
            
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
      for source in @sourceArr
        for feed in @feeds[source.id]
          @feedsList.markFeedAsRead feed,source
      
  refresh:()->
    console.log 'refresh!'
    if @currentSource
      nowSourceId = @currentSource.id
    @showMessage '正在刷新','loading'
    @apiGet 'source',null,(err,res)=>
      if err
        @showMessage '刷新失败','err'
        console.error err
        return
      @showMessage '完成'
      @initButtons()
      @sourceArr = res.data
      @initSourceList()
      @getFeedsOfAllSource =>
        return if !nowSourceId
        for sourceObj in @sourceArr
          if sourceObj.id is nowSourceId
            @showFeedsOfSource sourceObj
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
