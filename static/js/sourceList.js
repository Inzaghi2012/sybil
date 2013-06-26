(function() {

  window.SourceList = (function() {

    function SourceList(sybil) {
      this.sybil = sybil;
      this.widget = new Leaf.Widget("#sourceList");
      this.itemTemplate = window.leafTemplates['source-list-item'];
    }

    SourceList.prototype.clearAll = function() {
      return this.widget.$node.html('');
    };

    SourceList.prototype.addItem = function(source) {
      var arr, container, item, sybil, url;
      container = this.widget.$node;
      item = new Leaf.Widget(this.itemTemplate);
      console.log(item);
      item.node.id = source.id;
      item.UI.$source.text(source.title);
      if (source.unreadCount > 0) {
        item.UI.$unread.text("(" + source.unreadCount + ")");
        item.$node.addClass("unread");
      } else {
        item.UI.$unread.text("");
      }
      item.node.sourceObj = source;
      if (source.icon) {
        url = source.icon;
      } else {
        arr = source.link.split('/');
        url = arr[0] + '//' + arr[2] + '/favicon.ico';
      }
      item.UI.$img.attr("src", url).error(function() {
        return $(this.parentElement).html('<i class="icon-source-sign"></i>');
      });
      item.node$.appendTo(container);
      sybil = this.sybil;
      item.node.onclick = function() {
        var dom, _i, _len, _ref;
        console.log(this, 'clicked!!');
        _ref = $("#sourceList .sourceListItem");
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          dom = _ref[_i];
          $(dom).removeClass('active');
        }
        $(this).addClass('active');
        $("#feedsListBox")[0].scrollTop = 0;
        return sybil.showFeedsOfSource(this.sourceObj);
      };
      return item.node.oncontextmenu = function(evt) {
        var menu;
        console.log('right click', evt, this);
        evt.preventDefault();
        evt.stopPropagation();
        menu = new Leaf.Widget("#sourceItemMenu");
        if (menu.onshow) {
          menu.$node.fadeOut('fast');
          menu.onshow = false;
          return;
        }
        menu.$node.css('top', this.offsetTop + 10 + 'px');
        menu.$node.css('left', this.offsetLeft + 100 + 'px');
        menu.UI.$sourceTitle.text(this.sourceObj.title);
        menu.$node.fadeIn("fast");
        menu.onshow = true;
        menu.UI.unsubBtn.targetSource = this.sourceObj;
        menu.UI.unsubBtn.onclick = function() {
          sybil.showMessage('正在删除', 'loading');
          return sybil.apiGet('unsubscribe', {
            source: this.targetSource.id
          }, function(err, res) {
            if (err) {
              console.error(err);
              sybil.showMessage('删除失败', err);
              return;
            }
            menu.fadeOut('fast');
            sybil.showMessage('删除成功');
            return sybil.refresh();
          });
        };
        menu.UI.openlinkBtn.targetSource = this.sourceObj;
        menu.UI.openlinkBtn.onclick = function() {
          window.open(this.targetSource.link, '_blank');
          menu.onshow = false;
          return menu.fadeOut('fast');
        };
        return menu.UI.cancelBtn.onclick = function() {
          menu.onshow = false;
          return menu.fadeOut('fast');
        };
      };
    };

    SourceList.prototype.nextSource = function() {
      var dom, domArr, firstDom, index, nextDom, _i, _len, _results;
      if (this.sybil.currentPage === 'home') {
        this.sybil.showFeedsOfSource(this.sybil.sourceArr[0]);
        firstDom = $("#feedsList .feedItem")[0];
        this.focusFeed(firstDom);
        return;
      }
      domArr = $("#leftPanel .sourceListItem");
      console.log(domArr);
      _results = [];
      for (index = _i = 0, _len = domArr.length; _i < _len; index = ++_i) {
        dom = domArr[index];
        if ($(dom).hasClass('active') && index < domArr.length - 1) {
          $(dom).removeClass('active');
          nextDom = domArr[index + 1];
          $(nextDom).addClass('active');
          this.sybil.showFeedsOfSource(nextDom.sourceObj);
          firstDom = $("#feedsList .feedItem")[0];
          this.focusFeed(firstDom);
          break;
        } else {
          _results.push(void 0);
        }
      }
      return _results;
    };

    SourceList.prototype.lastSource = function() {
      var dom, domArr, firstDom, index, lastDom, _i, _len, _results;
      if (this.sybil.currentPage === 'home') {
        this.sybil.showFeedsOfSource(this.sybil.sourceArr[this.sybil.sourceArr.length - 1]);
        firstDom = $("#feedsList .feedItem")[0];
        this.focusFeed(firstDom);
        return;
      }
      domArr = $("#leftPanel .sourceListItem");
      _results = [];
      for (index = _i = 0, _len = domArr.length; _i < _len; index = ++_i) {
        dom = domArr[index];
        if ($(dom).hasClass('active') && index > 0) {
          $(dom).removeClass('active');
          lastDom = domArr[index - 1];
          $(lastDom).addClass('active');
          this.sybil.showFeedsOfSource(lastDom.sourceObj);
          firstDom = $("#feedsList .feedItem")[0];
          this.focusFeed(firstDom);
          break;
        } else {
          _results.push(void 0);
        }
      }
      return _results;
    };

    return SourceList;

  })();

}).call(this);
