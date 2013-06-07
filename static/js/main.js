(function() {
  var Sybil;

  Sybil = (function() {

    function Sybil() {
      var messageCenter,
        _this = this;
      console.log('init');
      this.rssArr = [];
      this.feeds = {};
      this.currentPage = 'home';
      this.apiGet('rss', null, function(err, res) {
        if (err) {
          console.error(err);
        }
        _this.initButtons();
        _this.rssArr = res.data;
        _this.initRssList();
        return _this.getFeedsOfAllRss();
      });
      messageCenter = new MessageCenter(41121);
      messageCenter.on("share", function(share) {
        console.log("shared", share);
        _this.showMessage('朋友们分享新文章了');
        $('#recommandPageBtn').addClass("unread");
        return $('#recommandPageBtn i').show();
      });
      messageCenter.on("control", function(action) {
        console.log("control", action);
        if (action === 'nextRss') {
          _this.nextRss();
        }
        if (action === 'lastRss') {
          _this.lastRss();
        }
        if (action === 'nextItem') {
          _this.nextItem();
        }
        if (action === 'lastItem') {
          return _this.lastItem();
        }
      });
    }

    Sybil.prototype.initRssList = function() {
      var arr, container, newJ, rss, sybil, template, url, _i, _len, _ref, _results;
      template = $("#templateBox .rssListItem");
      container = $("#rssList");
      container.html("");
      sybil = this;
      _ref = this.rssArr;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        rss = _ref[_i];
        newJ = template.clone();
        newJ[0].id = rss.id;
        newJ.find('.source').html(rss.title);
        if (rss.unreadCount > 0) {
          newJ.find('.unread').html("(" + rss.unreadCount + ")");
          newJ.addClass("unread");
        } else {
          newJ.find('.unread').html("");
        }
        newJ[0].rssObj = rss;
        arr = rss.link.split('/');
        url = arr[0] + '//' + arr[2] + '/favicon.ico';
        newJ.find('img').attr("src", url).error(function() {
          return $(this.parentElement).html('<i class="icon-rss-sign"></i>');
        });
        newJ.appendTo(container);
        newJ[0].onclick = function() {
          var dom, _j, _len1, _ref1;
          console.log(this, 'clicked!!');
          _ref1 = $("#rssList .rssListItem");
          for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
            dom = _ref1[_j];
            $(dom).removeClass('active');
          }
          $(this).addClass('active');
          $("#feedsListBox")[0].scrollTop = 0;
          return sybil.showFeedsOfRss(this.rssObj);
        };
        _results.push(newJ[0].oncontextmenu = function(evt) {
          var cancelBtn, menu, openlinkBtn, unsubBtn;
          console.log('right click', evt, this);
          evt.preventDefault();
          evt.stopPropagation();
          menu = $("#rssItemMenu");
          if (menu[0].onshow) {
            menu.fadeOut('fast');
            menu[0].onshow = false;
            return;
          }
          menu.css('top', this.offsetTop + 10 + 'px');
          menu.css('left', this.offsetLeft + 100 + 'px');
          menu.find("#sourceTitle").html(this.rssObj.title);
          menu.fadeIn("fast");
          menu[0].onshow = true;
          unsubBtn = menu.find("#unsubscribeBtn");
          unsubBtn[0].targetRss = this.rssObj;
          unsubBtn[0].onclick = function() {
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
          openlinkBtn = menu.find("#openlinkBtn");
          openlinkBtn[0].targetRss = this.rssObj;
          openlinkBtn[0].onclick = function() {
            window.open(this.targetRss.link, '_blank');
            menu.onshow = false;
            return menu.fadeOut('fast');
          };
          cancelBtn = menu.find("#cancelBtn");
          return cancelBtn[0].onclick = function() {
            menu.onshow = false;
            return menu.fadeOut('fast');
          };
        });
      }
      return _results;
    };

    Sybil.prototype.getFeedsOfAllRss = function(callback) {
      var count, rss, sum, _i, _len, _ref, _results,
        _this = this;
      console.log('get feeds');
      sum = this.rssArr.length;
      count = 0;
      _ref = this.rssArr;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        rss = _ref[_i];
        if (!rss.start) {
          rss.start = 0;
          rss.count = 10;
        }
        console.log(rss.id);
        if (rss.unreadCount === 0) {
          count += 1;
          continue;
        }
        this.apiGet('feed', {
          rss: rss.id,
          type: '',
          start: rss.start,
          count: rss.count
        }, function(err, res) {
          var rid, rssObj;
          if (err) {
            console.error(err);
          }
          if (res.data.feeds && res.data.feeds[0]) {
            rid = res.data.feeds[0].source;
            if (res.data.feeds) {
              _this.feeds[rid] = res.data.feeds;
            }
            rssObj = (function() {
              var r, _j, _len1, _ref1;
              _ref1 = _this.rssArr;
              for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
                r = _ref1[_j];
                if (r.id === rid) {
                  return r;
                }
              }
            })();
            console.log(_this.feeds, count);
          }
          count += 1;
          if (count === _this.rssArr.length) {
            if (typeof callback !== 'function') {
              return _this.showHomePage();
            } else {
              return callback();
            }
          }
        });
        _results.push(rss.start += rss.count);
      }
      return _results;
    };

    Sybil.prototype.getFeedsOfRss = function(rss, callback) {
      var _this = this;
      console.log('get more feeds');
      this.apiGet('feed', {
        rss: rss.id,
        type: '',
        start: rss.start,
        count: rss.count
      }, function(err, res) {
        if (err) {
          console.error(err);
        }
        if (res.data.feeds.length === 0) {
          return;
        }
        if (typeof callback === 'function') {
          return callback(res.data.feeds, res.data.drain);
        }
      });
      return rss.start += rss.count;
    };

    Sybil.prototype.showHomePage = function() {
      var container, dom, feed, feedsArr, newJ, rss, sybil, template, title, _i, _j, _len, _len1, _ref, _ref1;
      console.log('show main page');
      this.currentPage = 'home';
      _ref = $("#rssList .rssListItem");
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        dom = _ref[_i];
        $(dom).removeClass('active');
      }
      $('#homepageBtn').addClass('active');
      $('#recommandPageBtn').removeClass('active');
      $('#feedsListBoxTitle').html('主页 - 所有新条目');
      template = $("#templateBox .rssUpdateItem");
      container = $("#feedsList");
      container.html("");
      _ref1 = this.rssArr;
      for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
        rss = _ref1[_j];
        feedsArr = this.feeds[rss.id];
        if (!feedsArr) {
          continue;
        }
        if (feedsArr.length > 0) {
          feed = feedsArr[0];
          newJ = template.clone();
          newJ[0].rssObj = rss;
          title = rss.title + ("(" + rss.unreadCount + ")");
          newJ.find('.rssTitle').html(title);
          newJ.find('.articleTitle').html(feed.title);
          newJ.find('.content').html(feed.summary || feed.title);
          newJ.appendTo(container);
          sybil = this;
          newJ[0].onclick = function() {
            var _k, _len2, _ref2;
            console.log(this, 'clicked!!');
            _ref2 = $("#rssList .rssListItem");
            for (_k = 0, _len2 = _ref2.length; _k < _len2; _k++) {
              dom = _ref2[_k];
              if (dom.id === this.rssObj.id) {
                $(dom).addClass("active");
              } else {
                $(dom).removeClass('active');
              }
            }
            $("#feedsListBox")[0].scrollTop = 0;
            return sybil.showFeedsOfRss(this.rssObj);
          };
        }
      }
      return $('#templateBox .feedsListFooter').clone().appendTo(container);
    };

    Sybil.prototype.showRecommandedFeeds = function() {
      var callback, container, dom, template, _i, _len, _ref,
        _this = this;
      console.log('show recommanded page');
      _ref = $("#rssList .rssListItem");
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        dom = _ref[_i];
        $(dom).removeClass('active');
      }
      $("#recommandPageBtn").removeClass("unread");
      $('#recommandPageBtn i').hide();
      $('#homepageBtn').removeClass('active');
      $('#recommandPageBtn').addClass('active');
      this.currentRss = 'recommanded';
      container = $("#feedsList");
      container.html("");
      template = $("#templateBox .feedItem_normal");
      callback = function(err, res) {
        var feed, newJ, now, str, time, _j, _len1, _ref1, _results;
        _ref1 = res.data;
        _results = [];
        for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
          feed = _ref1[_j];
          newJ = template.clone();
          newJ[0].feedObj = feed;
          newJ[0].id = feed.id;
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

    Sybil.prototype.showFeedsOfRss = function(rss, type) {
      var a, container, dom, feed, feedsArr, listItem, newJ, now, str, sybil, template, time, _i, _j, _len, _len1, _ref,
        _this = this;
      if (type == null) {
        type = "normal";
      }
      console.log('show feeds in rss');
      console.log(rss, this.feeds[rss.id]);
      $('#homepageBtn').removeClass('active');
      $('#recommandPageBtn').removeClass('active');
      $("#leftPanel .rssListItem").removeClass('active');
      _ref = $("#leftPanel .rssListItem");
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        dom = _ref[_i];
        if (dom.rssObj === rss) {
          listItem = dom;
        }
      }
      $(listItem).addClass("active");
      this.currentRss = rss;
      this.currentPage = 'feeds';
      rss.ajaxLock = false;
      if (!this.feeds[rss.id]) {
        return;
      }
      sybil = this;
      if (type === "normal") {
        template = $("#templateBox .feedItem_normal");
      } else {
        template = $("#templateBox .feedItem_small");
      }
      container = $('#feedsList');
      container.html("");
      a = document.createElement("a");
      a.href = rss.link;
      a.title = rss.link;
      a.innerHTML = rss.title + "  <i class='icon-external-link'></>";
      $("#feedsListBoxTitle").html(a.outerHTML);
      $("#feedsListBoxTitle").hover((function() {
        return $(this).find('i').fadeIn('fast');
      }), (function() {
        return $(this).find('i').fadeOut('fast');
      }));
      feedsArr = this.feeds[rss.id];
      for (_j = 0, _len1 = feedsArr.length; _j < _len1; _j++) {
        feed = feedsArr[_j];
        newJ = template.clone();
        newJ[0].feedObj = feed;
        newJ[0].rssObj = rss;
        newJ[0].id = feed.id;
        time = new Date(rss.date);
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
          return sybil.markFeedAsRead(this.feedObj, this.rssObj);
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
      return $("#feedsListBox").scroll(function(evt) {
        var box, domArr, index, nowPos, rssListItem, _k, _len2;
        box = $("#feedsListBox");
        nowPos = box.scrollTop() + box[0].offsetHeight / 2;
        domArr = box.find(".feedItem");
        for (index = _k = 0, _len2 = domArr.length; _k < _len2; index = ++_k) {
          dom = domArr[index];
          if (dom.offsetTop < nowPos && dom.offsetTop + dom.offsetHeight >= nowPos) {
            _this.focusFeed(dom);
            $(dom).addClass('readed');
            if (index > domArr.length - 8) {
              _this.getMoreFeeds(dom.rssObj);
            }
            _this.markFeedAsRead(dom.feedObj, dom.rssObj);
            if (index === domArr.length - 1) {
              rssListItem = (function() {
                var _l, _len3, _ref1;
                _ref1 = $("#rssList .rssListItem");
                for (_l = 0, _len3 = _ref1.length; _l < _len3; _l++) {
                  dom = _ref1[_l];
                  if (dom.rssObj === rss) {
                    return dom;
                  }
                }
              })();
              if (!rssListItem) {
                return;
              }
              rss.unreadCount = 0;
              $(rssListItem).find(".unread").html("");
            }
            break;
          }
        }
      });
    };

    Sybil.prototype.focusFeed = function(dom) {
      $("#feedsListBox .feedItem").removeClass('focus');
      return $(dom).addClass('focus');
    };

    Sybil.prototype.getMoreFeeds = function(rss) {
      var container, sybil, template,
        _this = this;
      container = "#feedsList";
      if (rss.ajaxLock) {
        return;
      }
      rss.ajaxLock = true;
      console.warn('获取新feed');
      sybil = this;
      template = $("#templateBox .feedItem_normal");
      return this.getFeedsOfRss(rss, function(newFeeds, drain) {
        var feed, newJ, now, str, time, _i, _len;
        if (!rss.ajaxLock || sybil.currentRss !== rss) {
          return;
        }
        for (_i = 0, _len = newFeeds.length; _i < _len; _i++) {
          feed = newFeeds[_i];
          newJ = template.clone();
          newJ[0].feedObj = feed;
          newJ[0].rssObj = rss;
          newJ[0].id = feed.id;
          time = new Date(rss.date);
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
            return sybil.markFeedAsRead(this.feedObj, this.rssObj);
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
        rss.ajaxLock = false;
        console.log('~~~~~~~~~~', drain);
        if (drain) {
          return $('#templateBox .feedsListFooter').clone().appendTo(container);
        }
      });
    };

    Sybil.prototype.markFeedAsRead = function(feed, rss) {
      if (feed.read) {
        return;
      }
      feed.read = true;
      console.log("markFeedAsRead");
      return this.apiGet("read", {
        id: feed.id
      }, function(err, res) {
        var rssListItem;
        if (err) {
          console.error;
        }
        rss.unreadCount -= 1;
        if (rss.unreadCount <= 0) {
          return;
        }
        rssListItem = (function() {
          var dom, _i, _len, _ref;
          _ref = $("#rssList .rssListItem");
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            dom = _ref[_i];
            if (dom.rssObj === rss) {
              return dom;
            }
          }
        })();
        if (!rssListItem) {
          return;
        }
        if (rss.unreadCount > 0) {
          return $(rssListItem).find(".unread").html("(" + rss.unreadCount + ")");
        } else {
          return $(rssListItem).find(".unread").html("");
        }
      });
    };

    Sybil.prototype.initButtons = function() {
      var boxJ,
        _this = this;
      boxJ = $('#subscribePopup');
      $('#subscribeBtn')[0].onclick = function() {
        if (boxJ.onshow) {
          boxJ.fadeOut('fast');
          return boxJ.onshow = false;
        } else {
          boxJ.find("input").val("");
          boxJ.fadeIn('fast');
          return boxJ.onshow = true;
        }
      };
      boxJ.find("#applyBtn")[0].onclick = function() {
        var url;
        url = boxJ.find("input")[0].value;
        _this.showMessage('添加中', 'loading');
        boxJ.fadeOut('fast');
        return _this.apiGet('subscribe', {
          rss: url
        }, function(err, res) {
          if (err) {
            console.error(err, res);
            return _this.showMessage('添加订阅失败', 'err');
          } else {
            _this.showMessage('添加成功，现在刷新页面', 'loading');
            return _this.apiGet('rss', null, function(err, res) {
              _this.showMessage('完成');
              if (err) {
                console.error(err);
              }
              _this.initButtons();
              _this.rssArr = res.data;
              _this.initRssList();
              return _this.getFeedsOfAllRss();
            });
          }
        });
      };
      boxJ.find("#cancelBtn")[0].onclick = function() {
        boxJ.fadeOut('fast');
        return boxJ.onshow = false;
      };
      $("#homepageBtn")[0].onclick = function() {
        return _this.showHomePage();
      };
      $("#recommandPageBtn")[0].onclick = function() {
        return _this.showRecommandedFeeds();
      };
      $("#refreshBtn")[0].onclick = function() {
        return _this.refresh();
      };
      return $("#markAllReadBtn")[0].onclick = function() {
        var feed, rss, _i, _len, _ref, _results;
        console.log('mark all read btn clicked');
        _ref = _this.rssArr;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          rss = _ref[_i];
          _results.push((function() {
            var _j, _len1, _ref1, _results1;
            _ref1 = this.feeds[rss.id];
            _results1 = [];
            for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
              feed = _ref1[_j];
              _results1.push(this.markFeedAsRead(feed, rss));
            }
            return _results1;
          }).call(_this));
        }
        return _results;
      };
    };

    Sybil.prototype.refresh = function() {
      var nowRssId,
        _this = this;
      console.log('refresh!');
      if (this.currentRss) {
        nowRssId = this.currentRss.id;
      }
      this.showMessage('正在刷新', 'loading');
      return this.apiGet('rss', null, function(err, res) {
        if (err) {
          _this.showMessage('刷新失败', 'err');
          console.error(err);
          return;
        }
        _this.showMessage('完成');
        _this.initButtons();
        _this.rssArr = res.data;
        _this.initRssList();
        return _this.getFeedsOfAllRss(function() {
          var rssObj, _i, _len, _ref, _results;
          if (!nowRssId) {
            return;
          }
          _ref = _this.rssArr;
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            rssObj = _ref[_i];
            if (rssObj.id === nowRssId) {
              _this.showFeedsOfRss(rssObj);
              break;
            } else {
              _results.push(void 0);
            }
          }
          return _results;
        });
      });
    };

    Sybil.prototype.initFeedItemButtons = function(J) {
      var likeBtn, shareBtn, sybil;
      likeBtn = J.find('.likeBtn');
      shareBtn = J.find('.shareBtn');
      if (J[0].feedObj.liked) {
        likeBtn.addClass("active");
        likeBtn.find("i").attr("class", "icon-star");
      }
      if (J[0].feedObj.shared) {
        shareBtn.addClass("active");
      }
      sybil = this;
      likeBtn[0].onclick = function() {
        var _this = this;
        if (!J[0].feedObj.liked) {
          return sybil.apiGet('like', {
            id: J[0].feedObj.id
          }, function(err, res) {
            if (err) {
              console.error(err);
            }
            J[0].feedObj.liked = true;
            likeBtn.addClass("active");
            return likeBtn.find("i").attr("class", "icon-star");
          });
        } else {
          return sybil.apiGet('unlike', {
            id: J[0].feedObj.id
          }, function(err, res) {
            if (err) {
              console.error(err);
            }
            J[0].feedObj.liked = false;
            likeBtn.removeClass("active");
            return likeBtn.find("i").attr("class", "icon-star-empty");
          });
        }
      };
      return shareBtn[0].onclick = function() {
        if ($(this).hasClass('shared')) {
          return;
        }
        return sybil.apiGet('share', {
          id: J[0].feedObj.id
        }, function(err, res) {
          if (err) {
            console.error(err);
          }
          J[0].feedObj.shared = true;
          shareBtn.addClass("active");
          return sybil.showMessage('分享成功');
        });
      };
    };

    Sybil.prototype.apiGet = function(type, data, callback) {
      var req,
        _this = this;
      console.log("api.get!", "/api/" + type, data);
      req = $.get("/api/" + type, data, function(res, status, xhr) {
        console.log('ajax request successed', res);
        return callback(res.error, res);
      });
      return req.fail(function(err) {
        _this.showMessage('网络错误', 'err');
        return callback(err);
      });
    };

    Sybil.prototype.showMessage = function(msg, type) {
      var p,
        _this = this;
      if (type == null) {
        type = 'normal';
      }
      if (!this.msgBox) {
        this.msgBox = $("#messageBox");
        this.msgBox.onshow = false;
        this.msgBox.lastMsg = null;
      }
      p = this.msgBox.find("p");
      this.msgBox.fadeIn('fast');
      return p.fadeOut('fast', function() {
        var spinner;
        p.html(msg);
        if (type === 'error') {
          p.addClass('error');
        } else {
          p.removeClass('error');
        }
        spinner = _this.msgBox.find("#spinner");
        if (type === 'loading') {
          spinner.show();
        } else {
          spinner.hide();
        }
        if (type !== 'loading') {
          _this.msgBox.lastMsg = msg;
          window.setTimeout((function() {
            if (_this.msgBox.lastMsg === msg) {
              return _this.msgBox.fadeOut('fast');
            }
          }), 1000);
        }
        return p.fadeIn('fast');
      });
    };

    Sybil.prototype.nextItem = function() {
      var dom, domArr, firstDom, index, _i, _len, _results;
      if (this.currentPage === 'home') {
        this.showFeedsOfRss(this.rssArr[0]);
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

    Sybil.prototype.lastItem = function() {
      var dom, domArr, index, lastDom, _i, _len, _results;
      if (this.currentPage === 'home') {
        this.showFeedsOfRss(this.rssArr[this.rssArr.length - 1]);
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

    Sybil.prototype.nextRss = function() {
      var dom, domArr, firstDom, index, nextDom, _i, _len, _results;
      if (this.currentPage === 'home') {
        this.showFeedsOfRss(this.rssArr[0]);
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
          this.showFeedsOfRss(nextDom.rssObj);
          firstDom = $("#feedsList .feedItem")[0];
          this.focusFeed(firstDom);
          break;
        } else {
          _results.push(void 0);
        }
      }
      return _results;
    };

    Sybil.prototype.lastRss = function() {
      var dom, domArr, firstDom, index, lastDom, _i, _len, _results;
      if (this.currentPage === 'home') {
        this.showFeedsOfRss(this.rssArr[this.rssArr.length - 1]);
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
          this.showFeedsOfRss(lastDom.rssObj);
          firstDom = $("#feedsList .feedItem")[0];
          this.focusFeed(firstDom);
          break;
        } else {
          _results.push(void 0);
        }
      }
      return _results;
    };

    return Sybil;

  })();

  window.onload = function() {
    var sybil;
    return sybil = new Sybil;
  };

}).call(this);
