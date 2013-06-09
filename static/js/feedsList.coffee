class window.FeedsList
  constructor:(sybil)->
    @sybil = sybil
    @widget = new Leaf.Widget "#feedsList"
    @rssUpdateItemTpl = window.leafTemplates['rss-update-item']
    @feedItemNormalTpl = window.leafTemplates['feed-item-normal']
    @feedItemSmallTpl = window.leafTemplates['feed-item-small']
    @footerTpl = window.leafTemplates['feeds-list-footer']
    @loadingFooterTpl = window.leafTemplates['feeds-list-loading-footer']
  clearAll:()->
    @widget.$node.html ""
  showHomePage:(rssArr,feeds)->
  # home page will show updated rss
    @clearAll()
    sybil = @sybil
    template = @rssUpdateItemTpl
    
    $(dom).removeClass 'active' for dom in $ "#rssList .rssListItem"
    $('#homepageBtn').addClass 'active'
    $('#recommandPageBtn').removeClass 'active'
    $('#feedsListBoxTitle').text '主页 - 所有新条目'

    container = @widget.$node
    for rss in rssArr
      feedsArr = feeds[rss.id]
      if not feedsArr then continue
      #console.log @feeds
      if feedsArr.length > 0
        feed = feedsArr[0]
        #console.log feed
        item = new Leaf.Widget template
        item.node.rssObj = rss
        title = rss.title+"(#{rss.unreadCount})"
        item.UI.$rssTitle.text title
        item.UI.$articleTitle.text feed.title
        item.UI.$content.html feed.summary or feed.title

        item.$node.appendTo container
        
        item.node.onclick = ->
          console.log @,'clicked!!'
          for dom in $ "#rssList .rssListItem"
            if dom.id is @rssObj.id
              $(dom).addClass "active"
            else
              $(dom).removeClass 'active'

          $("#feedsListBox")[0].scrollTop = 0
          sybil.showFeedsOfRss @rssObj
          
    new Leaf.Widget(@footerTpl).$node.appendTo container
  showRecommandedFeeds:()->
    #TODO
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
  
  showFeedsOfRss:(rss,type)->
    sybil = @sybil
    rssArr = sybil.rssArr
    feeds = sybil.feeds
    rss.ajaxLock = false
    #ajax lock用于确保异步更新时不会因为切换页面而出问题
    # 或者重复更新操作

    @clearAll()
    container = @widget.$node
    if not feeds[rss.id] then return
    if type is "normal" 
      template  = @feedItemNormalTpl
    else template = @feedItemSmallTpl

    a = document.createElement "a"
    a.href = rss.link
    a.title = rss.link
    a.innerHTML = rss.title + "  <i class='icon-external-link'></>"
    $("#feedsListBoxTitle").html a.outerHTML
    $("#feedsListBoxTitle").hover (->$(@).find('i').fadeIn 'fast'),(->$(@).find('i').fadeOut 'fast')
    feedsArr = feeds[rss.id]
    feedsList = @
    for feed in feedsArr
      item = new Leaf.Widget template
      item.node.feedObj = feed
      item.node.rssObj = rss
      item.node.id = feed.id
      time = new Date(rss.date)
      now = new Date()
      if time.getYear() is now.getYear() and time.getMonth is now.getMonth() and time.getDay() is time.getDay()
        # same day
        str = '今天'+time.toString.split(' ')[4]
      else
        str = "#{time.getFullYear()}-#{time.getMonth()}-#{time.getDate()}"
      item.UI.$time.text str

      item.node.onclick = ()->
        console.warn @,'click'
        return if @feedObj.read
        $(@).addClass "readed"
        feedsList.markFeedAsRead @feedObj,@rssObj
      @initFeedItemButtons item
      item.UI.$feedTitle.text(feed.title).attr("href",feed.link).attr("target","_blank")
      item.UI.$author.text "作者：#{feed.author}"
      item.UI.$content.html feed.description or feed.summary or feed.title
      item.$node.addClass 'readed' if feed.read is true
      item.$node.appendTo container
    # if feedsArr.length < 10
    #   $('#templateBox .feedsListFooter').clone().appendTo container
    # else
    #   $('#templateBox .feedsListOnloadFooter').clone().appendTo container

    #scroll to read and scroll to ajax
    $("#feedsListBox").scroll (evt)=>
      console.log "scroll"
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
  initFeedItemButtons:(item)->
    sybil = @sybil
    likeBtnJ = item.UI.$likeBtn
    shareBtnJ = item.UI.$shareBtn
    if item.node.feedObj.liked
      likeBtnJ.addClass "active"
      likeBtnJ.find("i").attr "class","icon-star"
    if item.node.feedObj.shared
      shareBtnJ.addClass "active"
      
    likeBtnJ[0].onclick = ->
      if not item.node.feedObj.liked
        sybil.apiGet 'like',{id:item.node.feedObj.id},(err,res)=>
          console.error err if err
          item.node.feedObj.liked = true
          likeBtnJ.addClass "active"
          likeBtnJ.find("i").attr "class","icon-star"
      else
        sybil.apiGet 'unlike',{id:J[0].feedObj.id},(err,res)=>
          console.error err if err
          item.node.feedObj.liked = false
          likeBtnJ.removeClass "active"
          likeBtnJ.find("i").attr "class","icon-star-empty"

    shareBtnJ[0].onclick = ->
      return if $(@).hasClass 'shared'
      sybil.apiGet 'share',{id:item.node.feedObj.id},(err,res)->
        console.error err if err
        item.node.feedObj.shared = true
        shareBtnJ.addClass "active"
        sybil.showMessage '分享成功'

  getMoreFeeds:(rss)->
    #TODO
    container = @widget.$node
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
          sybil.feedsList.markFeedAsRead @feedObj,@rssObj
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
    
  focusFeed:(dom)->
    #console.log 'focus feed!!',dom
    $("#feedsListBox .feedItem").removeClass 'focus'
    $(dom).addClass 'focus'
    
  nextItem:()->
    if @sybil.currentPage is 'home'
      @sybil.showFeedsOfRss @sybil.rssArr[0]
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
    if @sybil.currentPage is 'home'
      @sybil.showFeedsOfRss @sybil.rssArr[@sybil.rssArr.length-1]
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
        
  markFeedAsRead:(feed,rss)->
    return if feed.read
    feed.read = true;
    console.log "markFeedAsRead"
    @sybil.apiGet "read",{id:feed.id},(err,res)->
      if err then console.error
      rss.unreadCount -= 1
      return if rss.unreadCount <= 0
      rssListItem = do ->
        for dom in $ "#rssList .rssListItem"
          if dom.rssObj is rss then return dom
      return if !rssListItem
      if rss.unreadCount > 0
        $(rssListItem).find(".unread").text "(#{rss.unreadCount})"
      else
        $(rssListItem).find(".unread").text ""
