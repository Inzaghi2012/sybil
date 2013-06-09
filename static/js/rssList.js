(function() {

  window.RssList = (function() {

    function RssList(sybil) {
      this.sybil = sybil;
      this.widget = new Leaf.Widget("#rssList");
      this.itemTemplate = window.leafTemplates['rss-list-item'];
    }

    RssList.prototype.clearAll = function() {
      return this.widget.$node.html('');
    };

    RssList.prototype.addItem = function(rss) {
      var arr, container, item, sybil, url;
      container = this.widget.$node;
      item = new Leaf.Widget(this.itemTemplate);
      console.log(item);
      item.node.id = rss.id;
      item.UI.$source.text(rss.title);
      if (rss.unreadCount > 0) {
        item.UI.$unread.text("(" + rss.unreadCount + ")");
        item.$node.addClass("unread");
      } else {
        item.UI.$unread.text("");
      }
      item.node.rssObj = rss;
      arr = rss.link.split('/');
      url = arr[0] + '//' + arr[2] + '/favicon.ico';
      item.UI.$img.attr("src", url).error(function() {
        return $(this.parentElement).html('<i class="icon-rss-sign"></i>');
      });
      item.node$.appendTo(container);
      sybil = this.sybil;
      item.node.onclick = function() {
        var dom, _i, _len, _ref;
        console.log(this, 'clicked!!');
        _ref = $("#rssList .rssListItem");
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          dom = _ref[_i];
          $(dom).removeClass('active');
        }
        $(this).addClass('active');
        $("#feedsListBox")[0].scrollTop = 0;
        return sybil.showFeedsOfRss(this.rssObj);
      };
      return item.node.oncontextmenu = function(evt) {
        var menu;
        console.log('right click', evt, this);
        evt.preventDefault();
        evt.stopPropagation();
        menu = new Leaf.Widget("#rssItemMenu");
        if (menu.onshow) {
          menu.$node.fadeOut('fast');
          menu.onshow = false;
          return;
        }
        menu.$node.css('top', this.offsetTop + 10 + 'px');
        menu.$node.css('left', this.offsetLeft + 100 + 'px');
        menu.UI.$sourceTitle.text(this.rssObj.title);
        menu.$node.fadeIn("fast");
        menu.onshow = true;
        menu.UI.unsubBtn.targetRss = this.rssObj;
        menu.UI.unsubBtn.onclick = function() {
          sybil.showMessage('正在删除', 'loading');
          return sybil.apiGet('unsubscribe', {
            rss: this.targetRss.id
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
        menu.UI.openlinkBtn.targetRss = this.rssObj;
        menu.UI.openlinkBtn.onclick = function() {
          window.open(this.targetRss.link, '_blank');
          menu.onshow = false;
          return menu.fadeOut('fast');
        };
        return menu.UI.cancelBtn.onclick = function() {
          menu.onshow = false;
          return menu.fadeOut('fast');
        };
      };
    };

    RssList.prototype.nextRss = function() {
      var dom, domArr, firstDom, index, nextDom, _i, _len, _results;
      if (this.sybil.currentPage === 'home') {
        this.sybil.showFeedsOfRss(this.sybil.rssArr[0]);
        firstDom = $("#feedsList .feedItem")[0];
        this.focusFeed(firstDom);
        return;
      }
      domArr = $("#leftPanel .rssListItem");
      console.log(domArr);
      _results = [];
      for (index = _i = 0, _len = domArr.length; _i < _len; index = ++_i) {
        dom = domArr[index];
        if ($(dom).hasClass('active') && index < domArr.length - 1) {
          $(dom).removeClass('active');
          nextDom = domArr[index + 1];
          $(nextDom).addClass('active');
          this.sybil.showFeedsOfRss(nextDom.rssObj);
          firstDom = $("#feedsList .feedItem")[0];
          this.focusFeed(firstDom);
          break;
        } else {
          _results.push(void 0);
        }
      }
      return _results;
    };

    RssList.prototype.lastRss = function() {
      var dom, domArr, firstDom, index, lastDom, _i, _len, _results;
      if (this.sybil.currentPage === 'home') {
        this.sybil.showFeedsOfRss(this.sybil.rssArr[this.sybil.rssArr.length - 1]);
        firstDom = $("#feedsList .feedItem")[0];
        this.focusFeed(firstDom);
        return;
      }
      domArr = $("#leftPanel .rssListItem");
      _results = [];
      for (index = _i = 0, _len = domArr.length; _i < _len; index = ++_i) {
        dom = domArr[index];
        if ($(dom).hasClass('active') && index > 0) {
          $(dom).removeClass('active');
          lastDom = domArr[index - 1];
          $(lastDom).addClass('active');
          this.sybil.showFeedsOfRss(lastDom.rssObj);
          firstDom = $("#feedsList .feedItem")[0];
          this.focusFeed(firstDom);
          break;
        } else {
          _results.push(void 0);
        }
      }
      return _results;
    };

    return RssList;

  })();

}).call(this);
