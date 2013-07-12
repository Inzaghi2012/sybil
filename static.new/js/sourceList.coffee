class window.SourceList
  constructor:(sybil)->
    @sybil = sybil
    @widget = new Leaf.Widget "#rssList"
    @itemTemplate = window.leafTemplates['source-list-item']
  clearAll:()->
    @widget.$node.html ''
  addItem:(source)->
    container = @widget.$node
    item = new Leaf.Widget @itemTemplate
    console.log item
    item.node.id = source.id
    item.UI.$source.text source.title
    if source.unreadCount > 0
      item.UI.$unread.text "(#{source.unreadCount})"
      item.$node.addClass "unread"
    else item.UI.$unread.text ""
    item.node.sourceObj = source
    if source.icon then url = source.icon
    else
      arr = source.link.split '/'
      url = arr[0]+'//'+arr[2]+'/favicon.ico'
    item.UI.$img.attr("src",url).error ->
      $(@parentElement).html '<i class="icon-source-sign"></i>'
    item.node$.appendTo container

    sybil = @sybil

    item.node.onclick = ->
      console.log @,'clicked!!'
      $(dom).removeClass 'active' for dom in $ "#rssList .rssListItem"
      $(@).addClass 'active'
      $("#feedsListBox")[0].scrollTop = 0
      sybil.showFeedsOfSource(@sourceObj)

    item.node.oncontextmenu = (evt)->
      console.log 'right click',evt,@
      evt.preventDefault()
      evt.stopPropagation()
      menu = new Leaf.Widget "#sourceItemMenu"
      if menu.onshow
        menu.$node.fadeOut 'fast'
        menu.onshow = false
        return
      menu.$node.css 'top',@offsetTop+10+'px'
      menu.$node.css 'left',@offsetLeft+100+'px'
      menu.UI.$sourceTitle.text @sourceObj.title
      menu.$node.fadeIn "fast"
      menu.onshow = true

      menu.UI.unsubBtn.targetSource = @sourceObj
      menu.UI.unsubBtn.onclick = ->
        sybil.showMessage '正在删除','loading'
        sybil.apiGet 'unsubscribe',{source:@targetSource.id},(err,res)->
          if err
            console.error err
            sybil.showMessage '删除失败',err
            return
          menu.fadeOut 'fast'
          sybil.showMessage '删除成功'
          sybil.refresh()
          
      menu.UI.openlinkBtn.targetSource = @sourceObj
      menu.UI.openlinkBtn.onclick = ->
        window.open(@targetSource.link,'_blank')
        menu.onshow = false
        menu.fadeOut 'fast'
        
      menu.UI.cancelBtn.onclick = ->
        menu.onshow = false
        menu.fadeOut 'fast'

  nextSource:()->
    if @sybil.currentPage is 'home'
      @sybil.showFeedsOfSource @sybil.sourceArr[0]
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
        @sybil.showFeedsOfSource nextDom.sourceObj
        firstDom = $("#feedsList .feedItem")[0]
        @focusFeed firstDom
        break
    
  lastSource:()->
    if @sybil.currentPage is 'home'
      @sybil.showFeedsOfSource @sybil.sourceArr[@sybil.sourceArr.length-1]
      firstDom = $("#feedsList .feedItem")[0]
      @focusFeed firstDom
      return
    domArr = $("#leftPanel .rssListItem")
    for dom,index in domArr
      if $(dom).hasClass('active')and index > 0
        $(dom).removeClass 'active'
        lastDom = domArr[index-1]
        $(lastDom).addClass 'active'
        @sybil.showFeedsOfSource lastDom.sourceObj
        firstDom = $("#feedsList .feedItem")[0]
        @focusFeed firstDom

        break
      
