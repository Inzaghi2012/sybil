class window.RssList
  constructor:(sybil)->
    @sybil = sybil
    @widget = new Leaf.Widget "#rssList"
    @itemTemplate = window.leafTemplates['rss-list-item']
  clearAll:()->
    @widget.$node.html ''
  addItem:(rss)->
    container = @widget.$node
    item = new Leaf.Widget @itemTemplate
    console.log item
    item.node.id = rss.id
    item.UI.$source.text rss.title
    if rss.unreadCount > 0
      item.UI.$unread.text "(#{rss.unreadCount})"
      item.$node.addClass "unread"
    else item.UI.$unread.text ""
    item.node.rssObj = rss
    arr = rss.link.split '/'
    url = arr[0]+'//'+arr[2]+'/favicon.ico'
    item.UI.$img.attr("src",url).error ->
      $(@.parentElement).html '<i class="icon-rss-sign"></i>'
    item.node$.appendTo container

    sybil = @sybil

    item.node.onclick = ->
      console.log @,'clicked!!'
      $(dom).removeClass 'active' for dom in $ "#rssList .rssListItem"
      $(@).addClass 'active'
      $("#feedsListBox")[0].scrollTop = 0
      sybil.showFeedsOfRss(@rssObj)

    item.node.oncontextmenu = (evt)->
      console.log 'right click',evt,@
      evt.preventDefault()
      evt.stopPropagation()
      menu = new Leaf.Widget "#rssItemMenu"
      if menu.onshow
        menu.$node.fadeOut 'fast'
        menu.onshow = false
        return
      menu.$node.css 'top',@offsetTop+10+'px'
      menu.$node.css 'left',@offsetLeft+100+'px'
      menu.UI.$sourceTitle.text @rssObj.title
      menu.$node.fadeIn "fast"
      menu.onshow = true

      menu.UI.unsubBtn.targetRss = @rssObj
      menu.UI.unsubBtn.onclick = ->
        sybil.showMessage '正在删除','loading'
        sybil.apiGet 'unsubscribe',{rss:@targetRss.id},(err,res)->
          if err
            console.error err
            sybil.showMessage '删除失败',err
            return
          menu.fadeOut 'fast'
          sybil.showMessage '删除成功'
          sybil.refresh()
          
      menu.UI.openlinkBtn.targetRss = @rssObj
      menu.UI.openlinkBtn.onclick = ->
        window.open(@targetRss.link,'_blank')
        menu.onshow = false
        menu.fadeOut 'fast'
        
      menu.UI.cancelBtn.onclick = ->
        menu.onshow = false
        menu.fadeOut 'fast'

  nextRss:()->
    if @sybil.currentPage is 'home'
      @sybil.showFeedsOfRss @sybil.rssArr[0]
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
        @sybil.showFeedsOfRss nextDom.rssObj
        firstDom = $("#feedsList .feedItem")[0]
        @focusFeed firstDom
        break
    
  lastRss:()->
    if @sybil.currentPage is 'home'
      @sybil.showFeedsOfRss @sybil.rssArr[@sybil.rssArr.length-1]
      firstDom = $("#feedsList .feedItem")[0]
      @focusFeed firstDom
      return
    domArr = $("#leftPanel .rssListItem")
    for dom,index in domArr
      if $(dom).hasClass('active')and index > 0
        $(dom).removeClass 'active'
        lastDom = domArr[index-1]
        $(lastDom).addClass 'active'
        @sybil.showFeedsOfRss lastDom.rssObj
        firstDom = $("#feedsList .feedItem")[0]
        @focusFeed firstDom

        break
      
