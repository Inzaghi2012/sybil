(function() {

  window.FeedsList = (function() {

    function FeedsList(sybil) {
      this.sybil = sybil;
      this.widget = new Leaf.Widget("#feedsList");
      this.sourceUpdateItemTpl = window.leafTemplates['source-update-item'];
      this.feedItemNormalTpl = window.leafTemplates['feed-item-normal'];
      this.feedItemSmallTpl = window.leafTemplates['feed-item-small'];
      this.footerTpl = window.leafTemplates['feeds-list-footer'];
      this.loadingFooterTpl = window.leafTemplates['feeds-list-loading-footer'];
    }

    FeedsList.prototype.clearAll = function() {
      return this.widget.$node.html("");
    };

    FeedsList.prototype.showHomePage = function(sourceArr, feeds) {
      var container, dom, feed, feedsArr, item, source, sybil, template, title, _i, _j, _len, _len1, _ref;
      this.clearAll();
      sybil = this.sybil;
      template = this.sourceUpdateItemTpl;
      _ref = $("#sourceList .sourceListItem");
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        dom = _ref[_i];
        $(dom).removeClass('active');
      }
      $('#homepageBtn').addClass('active');
      $('#recommandPageBtn').removeClass('active');
      $('#feedsListBoxTitle').text('主页 - 所有新条目');
      container = this.widget.$node;
      for (_j = 0, _len1 = sourceArr.length; _j < _len1; _j++) {
        source = sourceArr[_j];
        feedsArr = feeds[source.id];
        if (!feedsArr) {
          continue;
        }
        if (feedsArr.length > 0) {
          feed = feedsArr[0];
          item = new Leaf.Widget(template);
          item.node.sourceObj = source;
          title = source.title + ("(" + source.unreadCount + ")");
          item.UI.$sourceTitle.text(title);
          item.UI.$articleTitle.text(feed.title);
          item.UI.$content.html(feed.summary || feed.title);
          item.$node.appendTo(container);
          item.node.onclick = function() {
            var _k, _len2, _ref1;
            console.log(this, 'clicked!!');
            _ref1 = $("#sourceList .sourceListItem");
            for (_k = 0, _len2 = _ref1.length; _k < _len2; _k++) {
              dom = _ref1[_k];
              if (dom.id === this.sourceObj.id) {
                $(dom).addClass("active");
              } else {
                $(dom).removeClass('active');
              }
            }
            $("#feedsListBox")[0].scrollTop = 0;
            return sybil.showFeedsOfSource(this.sourceObj);
          };
        }
      }
      return new Leaf.Widget(this.footerTpl).$node.appendTo(container);
    };

    FeedsList.prototype.showRecommandedFeeds = function() {
      var callback, container, template,
        _this = this;
      container = $("#feedsList");
      container.html("");
      template = $("#templateBox .feedItem_normal");
      callback = function(err, res) {
        var feed, newJ, now, str, time, _i, _len, _ref, _results;
        _ref = res.data;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          feed = _ref[_i];
          newJ = template.clone();
          newJ[0].feedObj = feed;
          newJ[0].id = feed.guid;
          time = new Date(feed.date);
          now = new Date();
          if (time.getYear() === now.getYear() && time.getMonth === now.getMonth() && time.getDay() === time.getDay()) {
            str = '今天' + time.toString.split(' ')[4];
          } else {
            str = "" + (time.getFullYear()) + "-" + (time.getMonth()) + "-" + (time.getDate());
          }
          newJ.find('.time').html(str);
          _this.initFeedItemButtons(newJ);
          newJ.find('.feedTitle').html(feed.title).attr("href", feed.link).attr("target", "_blank");
          newJ.find('.author').html("作者：" + feed.author);
          newJ.find('.content').html(feed.description || feed.summary || feed.title);
          if (feed.read === true) {
            newJ.addClass('readed');
          }
          _results.push(newJ.appendTo(container));
        }
        return _results;
      };
      return this.apiGet('recommand', null, function(err, res) {
        if (err) {
          console.error(err);
        }
        return callback(err, res);
      });
    };

    FeedsList.prototype.showFeedsOfSource = function(source, type) {
      var a, container, feed, feeds, feedsArr, feedsList, item, now, sourceArr, str, sybil, template, time, _i, _len,
        _this = this;
      sybil = this.sybil;
      sourceArr = sybil.sourceArr;
      feeds = sybil.feeds;
      source.ajaxLock = false;
      this.clearAll();
      container = this.widget.$node;
      if (!feeds[source.id]) {
        return;
      }
      if (type === "normal") {
        template = this.feedItemNormalTpl;
      } else {
        template = this.feedItemSmallTpl;
      }
      a = document.createElement("a");
      a.href = source.link;
      a.title = source.link;
      a.innerHTML = source.title + "  <i class='icon-external-link'></>";
      $("#feedsListBoxTitle").html(a.outerHTML);
      $("#feedsListBoxTitle").hover((function() {
        return $(this).find('i').fadeIn('fast');
      }), (function() {
        return $(this).find('i').fadeOut('fast');
      }));
      feedsArr = feeds[source.id];
      feedsList = this;
      for (_i = 0, _len = feedsArr.length; _i < _len; _i++) {
        feed = feedsArr[_i];
        item = new Leaf.Widget(template);
        item.node.feedObj = feed;
        item.node.sourceObj = source;
        item.node.id = feed.guid;
        time = new Date(source.date);
        now = new Date();
        if (time.getYear() === now.getYear() && time.getMonth === now.getMonth() && time.getDay() === time.getDay()) {
          str = '今天' + time.toString.split(' ')[4];
        } else {
          str = "" + (time.getFullYear()) + "-" + (time.getMonth()) + "-" + (time.getDate());
        }
        item.UI.$time.text(str);
        item.node.onclick = function() {
          console.warn(this, 'click');
          if (this.feedObj.read) {
            return;
          }
          $(this).addClass("readed");
          return feedsList.markFeedAsRead(this.feedObj, this.sourceObj);
        };
        this.initFeedItemButtons(item);
        item.UI.$feedTitle.text(feed.title).attr("href", feed.link).attr("target", "_blank");
        item.UI.$author.text("作者：" + feed.author);
        item.UI.$content.html(feed.description || feed.summary || feed.title);
        if (feed.read === true) {
          item.$node.addClass('readed');
        }
        item.$node.appendTo(container);
      }
      return $("#feedsListBox").scroll(function(evt) {
        var box, dom, domArr, index, nowPos, sourceListItem, _j, _len1;
        console.log("scroll");
        box = $("#feedsListBox");
        nowPos = box.scrollTop() + box[0].offsetHeight / 2;
        domArr = box.find(".feedItem");
        for (index = _j = 0, _len1 = domArr.length; _j < _len1; index = ++_j) {
          dom = domArr[index];
          if (dom.offsetTop < nowPos && dom.offsetTop + dom.offsetHeight >= nowPos) {
            _this.focusFeed(dom);
            $(dom).addClass('readed');
            if (index > domArr.length - 8) {
              _this.getMoreFeeds(dom.sourceObj);
            }
            _this.markFeedAsRead(dom.feedObj, dom.sourceObj);
            if (index === domArr.length - 1) {
              sourceListItem = (function() {
                var _k, _len2, _ref;
                _ref = $("#sourceList .sourceListItem");
                for (_k = 0, _len2 = _ref.length; _k < _len2; _k++) {
                  dom = _ref[_k];
                  if (dom.sourceObj === source) {
                    return dom;
                  }
                }
              })();
              if (!sourceListItem) {
                return;
              }
              source.unreadCount = 0;
              $(sourceListItem).find(".unread").html("");
            }
            break;
          }
        }
      });
    };

    FeedsList.prototype.initFeedItemButtons = function(item) {
      var likeBtnJ, shareBtnJ, sybil;
      sybil = this.sybil;
      likeBtnJ = item.UI.$likeBtn;
      shareBtnJ = item.UI.$shareBtn;
      if (item.node.feedObj.liked) {
        likeBtnJ.addClass("active");
        likeBtnJ.find("i").attr("class", "icon-star");
      }
      if (item.node.feedObj.shared) {
        shareBtnJ.addClass("active");
      }
      likeBtnJ[0].onclick = function() {
        var _this = this;
        if (!item.node.feedObj.liked) {
          return sybil.apiGet('like', {
            id: item.node.feedObj.id
          }, function(err, res) {
            if (err) {
              console.error(err);
            }
            item.node.feedObj.liked = true;
            likeBtnJ.addClass("active");
            return likeBtnJ.find("i").attr("class", "icon-star");
          });
        } else {
          return sybil.apiGet('unlike', {
            id: J[0].feedObj.id
          }, function(err, res) {
            if (err) {
              console.error(err);
            }
            item.node.feedObj.liked = false;
            likeBtnJ.removeClass("active");
            return likeBtnJ.find("i").attr("class", "icon-star-empty");
          });
        }
      };
      return shareBtnJ[0].onclick = function() {
        if ($(this).hasClass('shared')) {
          return;
        }
        return sybil.apiGet('share', {
          id: item.node.feedObj.id
        }, function(err, res) {
          if (err) {
            console.error(err);
          }
          item.node.feedObj.shared = true;
          shareBtnJ.addClass("active");
          return sybil.showMessage('分享成功');
        });
      };
    };

    FeedsList.prototype.getMoreFeeds = function(source) {
      var container, sybil, template,
        _this = this;
      container = this.widget.$node;
      if (source.ajaxLock) {
        return;
      }
      source.ajaxLock = true;
      console.warn('获取新feed');
      sybil = this;
      template = $("#templateBox .feedItem_normal");
      return this.getFeedsOfSource(source, function(newFeeds, drain) {
        var feed, newJ, now, str, time, _i, _len;
        if (!source.ajaxLock || sybil.currentSource !== source) {
          return;
        }
        for (_i = 0, _len = newFeeds.length; _i < _len; _i++) {
          feed = newFeeds[_i];
          newJ = template.clone();
          newJ[0].feedObj = feed;
          newJ[0].sourceObj = source;
          newJ[0].id = feed.guid;
          time = new Date(source.date);
          now = new Date();
          if (time.getYear() === now.getYear() && time.getMonth === now.getMonth() && time.getDay() === time.getDay()) {
            str = '今天' + time.toString.split(' ')[4];
          } else {
            str = "" + (time.getFullYear()) + "-" + (time.getMonth()) + "-" + (time.getDate());
          }
          newJ.find('.time').html(str);
          newJ[0].onclick = function() {
            console.warn(this, 'click');
            if (this.feedObj.read) {
              return;
            }
            $(this).addClass("readed");
            return sybil.feedsList.markFeedAsRead(this.feedObj, this.sourceObj);
          };
          sybil.initFeedItemButtons(newJ);
          newJ.find('.feedTitle').html(feed.title).attr("href", feed.link).attr("target", "_blank");
          newJ.find('.author').html("作者：" + feed.author);
          newJ.find('.content').html(feed.description || feed.summary || feed.title);
          if (feed.read === true) {
            newJ.addClass('readed');
          }
          newJ.appendTo(container);
        }
        source.ajaxLock = false;
        console.log('~~~~~~~~~~', drain);
        if (drain) {
          return $('#templateBox .feedsListFooter').clone().appendTo(container);
        }
      });
    };

    FeedsList.prototype.focusFeed = function(dom) {
      $("#feedsListBox .feedItem").removeClass('focus');
      return $(dom).addClass('focus');
    };

    FeedsList.prototype.nextItem = function() {
      var dom, domArr, firstDom, index, _i, _len, _results;
      if (this.sybil.currentPage === 'home') {
        this.sybil.showFeedsOfSource(this.sybil.sourceArr[0]);
        firstDom = $("#feedsList .feedItem")[0];
        this.focusFeed(firstDom);
        return;
      }
      domArr = $("#feedsList .feedItem");
      _results = [];
      for (index = _i = 0, _len = domArr.length; _i < _len; index = ++_i) {
        dom = domArr[index];
        if ($(dom).hasClass('focus') && index < domArr.length - 1) {
          $("#feedsListBox").scrollTop(domArr[index + 1].offsetTop);
          this.focusFeed(domArr[index + 1]);
          break;
        } else {
          _results.push(void 0);
        }
      }
      return _results;
    };

    FeedsList.prototype.lastItem = function() {
      var dom, domArr, index, lastDom, _i, _len, _results;
      if (this.sybil.currentPage === 'home') {
        this.sybil.showFeedsOfSource(this.sybil.sourceArr[this.sybil.sourceArr.length - 1]);
        domArr = $("#feedsList .feedItem");
        lastDom = domArr[domArr.length - 1];
        this.focusFeed(lastDom);
        return;
      }
      console.log('last item');
      domArr = $("#feedsList .feedItem");
      _results = [];
      for (index = _i = 0, _len = domArr.length; _i < _len; index = ++_i) {
        dom = domArr[index];
        if ($(dom).hasClass('focus') && index > 0) {
          console.log('enter!!!');
          $("#feedsListBox").scrollTop(domArr[index - 1].offsetTop);
          this.focusFeed(domArr[index - 1]);
          break;
        } else {
          _results.push(void 0);
        }
      }
      return _results;
    };

    FeedsList.prototype.markFeedAsRead = function(feed, source) {
      if (feed.read) {
        return;
      }
      feed.read = true;
      console.log("markFeedAsRead");
      return this.sybil.apiGet("read", {
        id: feed.guid
      }, function(err, res) {
        var sourceListItem;
        if (err) {
          console.error;
        }
        source.unreadCount -= 1;
        if (source.unreadCount <= 0) {
          return;
        }
        sourceListItem = (function() {
          var dom, _i, _len, _ref;
          _ref = $("#sourceList .sourceListItem");
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            dom = _ref[_i];
            if (dom.sourceObj === source) {
              return dom;
            }
          }
        })();
        if (!sourceListItem) {
          return;
        }
        if (source.unreadCount > 0) {
          return $(sourceListItem).find(".unread").text("(" + source.unreadCount + ")");
        } else {
          return $(sourceListItem).find(".unread").text("");
        }
      });
    };

    return FeedsList;

  })();

}).call(this);
