class Sybil
  constructor:()->
    console.log 'init'
    @rssArr = []
    @feeds = {}
    @currentPage = 'home'
    @apiGet 'rss',null,(err,res)=>
      if err then console.error err
      @initButtons()
      @rssArr = res.data
      @initRssList()
      @getFeedsOfAllRss()
    messageCenter = new MessageCenter(41123)
    messageCenter.on "share",(share)=>
      console.log "shared",share
      @showMessage '朋友们分享新文章了'
      $('#recommandPageBtn').addClass "unread"
      $('#recommandPageBtn i').show()
      
    messageCenter.on "control",(action)=>
      console.log "control",action
      @nextRss() if action is 'nextRss'
      @lastRss() if action is 'lastRss'
      @nextItem() if action is 'nextItem'
      @lastItem() if action is 'lastItem'
        
  initRssList:()->
    template = $ "#templateBox .rssListItem"
    container = $ "#rssList"
    container.html "" 
    sybil = @
    
    for rss in @rssArr
      newJ = template.clone()
      newJ[0].id = rss.id
      newJ.find('.source').html rss.title
      if rss.unreadCount > 0
        newJ.find('.unread').html "(#{rss.unreadCount})"
        newJ.addClass "unread"
      else newJ.find('.unread').html ""
      newJ[0].rssObj = rss;
      arr = rss.link.split '/'
      url = arr[0]+'//'+arr[2]+'/favicon.ico'
      newJ.find('img').attr("src",url).error ->
        $(@.parentElement).html '<i class="icon-rss-sign"></i>'
      newJ.appendTo container

      newJ[0].onclick = ->
        console.log @,'clicked!!'
        $(dom).removeClass 'active' for dom in $ "#rssList .rssListItem"
        $(@).addClass 'active'
        $("#feedsListBox")[0].scrollTop = 0
        sybil.showFeedsOfRss(@rssObj)

      newJ[0].oncontextmenu = (evt)->
        console.log 'right click',evt,@
        evt.preventDefault()
        evt.stopPropagation()
        menu = $ "#rssItemMenu"
        if menu[0].onshow
          menu.fadeOut 'fast'
          menu[0].onshow = false
          return
        menu.css 'top',@offsetTop+10+'px'
        menu.css 'left',@offsetLeft+100+'px'
        menu.find("#sourceTitle").html @rssObj.title
        menu.fadeIn "fast"
        menu[0].onshow = true

        unsubBtn =  menu.find("#unsubscribeBtn")
        unsubBtn[0].targetRss = @rssObj
        unsubBtn[0].onclick = ->
          sybil.showMessage '正在删除','loading'
          sybil.apiGet 'unsubscribe',{rss:@targetRss.id},(err,res)->
            if err
              console.error err
              sybil.showMessage '删除失败',err
              return
            menu.fadeOut 'fast'
            sybil.showMessage '删除成功'
            sybil.refresh()
        openlinkBtn = menu.find "#openlinkBtn"
        openlinkBtn[0].targetRss = @rssObj
        openlinkBtn[0].onclick = ->
          window.open(@targetRss.link,'_blank')
          menu.onshow = false
          menu.fadeOut 'fast'
        cancelBtn = menu.find "#cancelBtn"
        cancelBtn[0].onclick = ->
          menu.onshow = false
          menu.fadeOut 'fast'

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
    console.log 'show main page'
    @currentPage = 'home'
    $(dom).removeClass 'active' for dom in $ "#rssList .rssListItem"
    $('#homepageBtn').addClass 'active'
    $('#recommandPageBtn').removeClass 'active'
    $('#feedsListBoxTitle').html '主页 - 所有新条目'
    template = $ "#templateBox .rssUpdateItem"
    container = $ "#feedsList"
    container.html ""
    for rss in @rssArr
      feedsArr = @feeds[rss.id]
      if not feedsArr then continue
      #console.log @feeds
      if feedsArr.length > 0
        feed = feedsArr[0]
        #console.log feed
        newJ = template.clone()
        newJ[0].rssObj = rss
        title = rss.title+"(#{rss.unreadCount})"
        newJ.find('.rssTitle').html title
        newJ.find('.articleTitle').html feed.title
        newJ.find('.content').html feed.summary or feed.title

        newJ.appendTo container
        sybil = @
        
        newJ[0].onclick = ->
          console.log @,'clicked!!'
          for dom in $ "#rssList .rssListItem"
            if dom.id is @rssObj.id
              $(dom).addClass "active"
            else
              $(dom).removeClass 'active'

          $("#feedsListBox")[0].scrollTop = 0
          sybil.showFeedsOfRss @rssObj
    $('#templateBox .feedsListFooter').clone().appendTo container
    
  showRecommandedFeeds:()->
    console.log 'show recommanded page'
    $(dom).removeClass 'active' for dom in $ "#rssList .rssListItem"
    $("#recommandPageBtn").removeClass "unread"
    $('#recommandPageBtn i').hide()
    $('#homepageBtn').removeClass 'active'
    $('#recommandPageBtn').addClass 'active'

    @currentRss = 'recommanded'
    container = $ "#feedsList"
    container.html ""
    template = $ "#templateBox .feedItem_normal"

    callback  = (err,res)=>
      for feed in res.data
        newJ = template.clone()
        newJ[0].feedObj = feed
        newJ[0].id = feed.id
        time = new Date(feed.date)
        now = new Date()
        if time.getYear() is now.getYear() and time.getMonth is now.getMonth() and time.getDay() is time.getDay()
          # same day
          str = '今天'+time.toString.split(' ')[4]
        else
          str = "#{time.getFullYear()}-#{time.getMonth()}-#{time.getDate()}"
        newJ.find('.time').html str
        
        @initFeedItemButtons newJ
        newJ.find('.feedTitle').html(feed.title).attr("href",feed.link).attr("target","_blank")
        newJ.find('.author').html "作者：#{feed.author}"
        newJ.find('.content').html feed.description or feed.summary or feed.title
        newJ.addClass 'readed' if feed.read is true
        newJ.appendTo container

      
    @apiGet 'recommand',null,(err,res)->
      console.error err if err
      callback(err,res)
    
    
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
    rss.ajaxLock = false
    #ajax lock用于确保异步更新时不会因为切换页面而出问题
    # 或者重复更新操作
    if not @feeds[rss.id] then return
    sybil = @
    if type is "normal" 
      template  = $ "#templateBox .feedItem_normal"
    else template = $ "#templateBox .feedItem_small"
    container = $ '#feedsList'
    container.html ""

    a = document.createElement "a"
    a.href = rss.link
    a.title = rss.link
    a.innerHTML = rss.title + "  <i class='icon-external-link'></>"
    $("#feedsListBoxTitle").html a.outerHTML
    $("#feedsListBoxTitle").hover (->$(@).find('i').fadeIn 'fast'),(->$(@).find('i').fadeOut 'fast')
    feedsArr = @feeds[rss.id]
    for feed in feedsArr
      newJ = template.clone()
      newJ[0].feedObj = feed
      newJ[0].rssObj = rss
      newJ[0].id = feed.id
      time = new Date(rss.date)
      now = new Date()
      if time.getYear() is now.getYear() and time.getMonth is now.getMonth() and time.getDay() is time.getDay()
        # same day
        str = '今天'+time.toString.split(' ')[4]
      else
        str = "#{time.getFullYear()}-#{time.getMonth()}-#{time.getDate()}"
      newJ.find('.time').html str

      newJ[0].onclick = ()->
        console.warn @,'click'
        return if @feedObj.read
        $(@).addClass "readed"
        sybil.markFeedAsRead @feedObj,@rssObj
      sybil.initFeedItemButtons newJ
      newJ.find('.feedTitle').html(feed.title).attr("href",feed.link).attr("target","_blank")
      newJ.find('.author').html "作者：#{feed.author}"
      newJ.find('.content').html feed.description or feed.summary or feed.title
      newJ.addClass 'readed' if feed.read is true
      newJ.appendTo container
    # if feedsArr.length < 10
    #   $('#templateBox .feedsListFooter').clone().appendTo container
    # else
    #   $('#templateBox .feedsListOnloadFooter').clone().appendTo container

    #scroll to read and scroll to ajax
    $("#feedsListBox").scroll (evt)=>
      box = $("#feedsListBox")
      nowPos = box.scrollTop()+box[0].offsetHeight/2
      #console.log nowPos
      domArr = box.find ".feedItem"
      for dom,index in domArr
        if dom.offsetTop < nowPos and dom.offsetTop+dom.offsetHeight >= nowPos
          @focusFeed dom
          $(dom).addClass 'readed'
          if index > domArr.length-8 then @getMoreFeeds dom.rssObj
          @markFeedAsRead dom.feedObj,dom.rssObj
          if index == domArr.length-1
            rssListItem = do ->
              for dom in $ "#rssList .rssListItem"
                if dom.rssObj is rss then return dom
            return if !rssListItem
            rss.unreadCount = 0
            $(rssListItem).find(".unread").html ""
          break
          
  focusFeed:(dom)->
    #console.log 'focus feed!!',dom
    $("#feedsListBox .feedItem").removeClass 'focus'
    $(dom).addClass 'focus'
    
  getMoreFeeds:(rss)->
    container = "#feedsList"
    #console.log container
    return if rss.ajaxLock
    rss.ajaxLock = true
    #container.remove ".feedsListFooter"
    console.warn '获取新feed'
    sybil = @
    template = $ "#templateBox .feedItem_normal"
    @getFeedsOfRss rss,(newFeeds,drain)=>
      return if !rss.ajaxLock or sybil.currentRss isnt rss
      for feed in newFeeds
        newJ = template.clone()
        newJ[0].feedObj = feed
        newJ[0].rssObj = rss
        newJ[0].id = feed.id
        time = new Date(rss.date)
        now = new Date()
        if time.getYear() is now.getYear() and time.getMonth is now.getMonth() and time.getDay() is time.getDay()
          # same day
          str = '今天'+time.toString.split(' ')[4]
        else
          str = "#{time.getFullYear()}-#{time.getMonth()}-#{time.getDate()}"
        newJ.find('.time').html str
        newJ[0].onclick= ()->
          console.warn @,'click'
          return if @feedObj.read
          $(@).addClass "readed"
          sybil.markFeedAsRead @feedObj,@rssObj
        sybil.initFeedItemButtons newJ
        newJ.find('.feedTitle').html(feed.title).attr("href",feed.link).attr("target","_blank")
        newJ.find('.author').html "作者：#{feed.author}"
        newJ.find('.content').html feed.description or feed.summary or feed.title
        newJ.addClass 'readed' if feed.read is true
        newJ.appendTo container
      rss.ajaxLock = false
      console.log '~~~~~~~~~~',drain
      if drain
        $('#templateBox .feedsListFooter').clone().appendTo container
      
      # else
      #   $('#templateBox .feedsListOnloadFooter').clone().appendTo container
  markFeedAsRead:(feed,rss)->
    return if feed.read
    feed.read = true;
    console.log "markFeedAsRead"
    @apiGet "read",{id:feed.id},(err,res)->
      if err then console.error
      rss.unreadCount -= 1
      return if rss.unreadCount <= 0
      rssListItem = do ->
        for dom in $ "#rssList .rssListItem"
          if dom.rssObj is rss then return dom
      return if !rssListItem
      if rss.unreadCount > 0
        $(rssListItem).find(".unread").html "(#{rss.unreadCount})"
      else
        $(rssListItem).find(".unread").html ""
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
          @markFeedAsRead feed,rss
      
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
    likeBtn = J.find '.likeBtn'
    shareBtn = J.find '.shareBtn'
    if J[0].feedObj.liked
      likeBtn.addClass "active"
      likeBtn.find("i").attr "class","icon-star"
    if J[0].feedObj.shared
      shareBtn.addClass "active"
    sybil = @
    likeBtn[0].onclick = ->
      if not J[0].feedObj.liked
        sybil.apiGet 'like',{id:J[0].feedObj.id},(err,res)=>
          console.error err if err
          J[0].feedObj.liked = true
          likeBtn.addClass "active"
          likeBtn.find("i").attr "class","icon-star"
      else
        sybil.apiGet 'unlike',{id:J[0].feedObj.id},(err,res)=>
          console.error err if err
          J[0].feedObj.liked = false
          likeBtn.removeClass "active"
          likeBtn.find("i").attr "class","icon-star-empty"

    shareBtn[0].onclick = ->
      return if $(@).hasClass 'shared'
      sybil.apiGet 'share',{id:J[0].feedObj.id},(err,res)->
        console.error err if err
        J[0].feedObj.shared = true
        shareBtn.addClass "active"
        sybil.showMessage '分享成功'

    
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
      
  nextItem:()->
    if @currentPage is 'home'
      @showFeedsOfRss @rssArr[0]
      firstDom = $("#feedsList .feedItem")[0]
      @focusFeed firstDom
      return
    domArr =  $("#feedsList .feedItem")
    for dom,index in domArr
      if $(dom).hasClass('focus') and index<domArr.length-1
        $("#feedsListBox").scrollTop domArr[index+1].offsetTop
        @focusFeed domArr[index+1]
        break
      
  lastItem:()->

    if @currentPage is 'home'
      @showFeedsOfRss @rssArr[@rssArr.length-1]
      domArr = $("#feedsList .feedItem")
      lastDom =  domArr[domArr.length-1]
      @focusFeed lastDom
      return
    console.log 'last item'
    domArr =  $("#feedsList .feedItem")
    for dom,index in domArr
      if $(dom).hasClass('focus') and index>0
        console.log 'enter!!!'
        $("#feedsListBox").scrollTop domArr[index-1].offsetTop
        @focusFeed domArr[index-1]
        break
    
  nextRss:()->
    if @currentPage is 'home'
      @showFeedsOfRss @rssArr[0]
      firstDom = $("#feedsList .feedItem")[0]
      @focusFeed firstDom
      return
    domArr = $("#leftPanel .rssListItem")
    console.log domArr
    for dom,index in domArr
      if $(dom).hasClass('active')and index<domArr.length-1
        $(dom).removeClass 'active'
        nextDom = domArr[index+1]
        $(nextDom).addClass 'active'
        @showFeedsOfRss nextDom.rssObj
        firstDom = $("#feedsList .feedItem")[0]
        @focusFeed firstDom
        break
    
  lastRss:()->
    if @currentPage is 'home'
      @showFeedsOfRss @rssArr[@rssArr.length-1]
      firstDom = $("#feedsList .feedItem")[0]
      @focusFeed firstDom
      return
    domArr = $("#leftPanel .rssListItem")
    for dom,index in domArr
      if $(dom).hasClass('active')and index > 0
        $(dom).removeClass 'active'
        lastDom = domArr[index-1]
        $(lastDom).addClass 'active'
        @showFeedsOfRss lastDom.rssObj
        firstDom = $("#feedsList .feedItem")[0]
        @focusFeed firstDom

        break
      
window.onload = ()->
  sybil = new Sybil