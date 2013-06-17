(function() {
  var Sybil;

  Sybil = (function() {

    function Sybil() {
      var _this = this;
      console.log('sybil init');
      this.sourceArr = [];
      this.feeds = {};
      this.currentPage = 'home';
      window.TemplateManager = new Leaf.TemplateManager();
      window.TemplateManager.use("feed-item-normal", "source-list-item", "feeds-list-footer", "feeds-list-loading-footer", "source-update-item", "authed-node-list", "authed-node-list-item");
      window.TemplateManager.on("ready", function(templates) {
        window.leafTemplates = templates;
        window.authedNodeList = new AuthedNodeList();
        authedNodeList.update();
        authedNodeList.appendTo(document.body);
        return _this.apiGet('source', null, function(err, res) {
          var source, _i, _len, _ref;
          if (err) {
            console.error(err);
          }
          _this.initButtons();
          _this.sourceArr = res.data;
          _ref = _this.sourceArr;
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            source = _ref[_i];
            source.id = source.source;
          }
          _this.initSourceList();
          _this.initFeedsLIst();
          return _this.getFeedsOfAllSource();
        });
      });
      window.TemplateManager.start();
    }

    Sybil.prototype.initSourceList = function() {
      var source, _i, _len, _ref;
      this.sourceList = new SourceList(this);
      this.sourceList.clearAll();
      _ref = this.sourceArr;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        source = _ref[_i];
        this.sourceList.addItem(source);
      }
      return console.log(this.sourceList);
    };

    Sybil.prototype.initFeedsLIst = function() {
      this.feedsList = new FeedsList(this);
      return this.feedsList.clearAll();
    };

    Sybil.prototype.getFeedsOfAllSource = function(callback) {
      var count, source, sum, _i, _len, _ref, _results,
        _this = this;
      console.log('get feeds');
      sum = this.sourceArr.length;
      count = 0;
      _ref = this.sourceArr;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        source = _ref[_i];
        if (!source.offset) {
          source.offset = 0;
          source.count = 10;
        }
        console.log(source.id);
        if (source.unreadCount === 0) {
          count += 1;
          continue;
        }
        this.apiGet('feed', {
          source: source.id,
          type: '',
          offset: source.offset,
          count: source.count
        }, function(err, res) {
          var rid, sourceObj;
          if (err) {
            console.error(err);
          }
          if (res.data.feeds && res.data.feeds[0]) {
            rid = res.data.feeds[0].source;
            if (res.data.feeds) {
              _this.feeds[rid] = res.data.feeds;
            }
            sourceObj = (function() {
              var r, _j, _len1, _ref1;
              _ref1 = _this.sourceArr;
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
          if (count === _this.sourceArr.length) {
            if (typeof callback !== 'function') {
              return _this.showHomePage();
            } else {
              return callback();
            }
          }
        });
        _results.push(source.offset += source.count);
      }
      return _results;
    };

    Sybil.prototype.getFeedsOfSource = function(source, callback) {
      var _this = this;
      console.log('get more feeds');
      this.apiGet('feed', {
        source: source.id,
        type: '',
        offset: source.offset,
        count: source.count
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
      return source.offset += source.count;
    };

    Sybil.prototype.showHomePage = function() {
      console.log('show home page /main page');
      this.currentPage = 'home';
      return this.feedsList.showHomePage(this.sourceArr, this.feeds);
    };

    Sybil.prototype.showRecommandedFeeds = function() {
      var dom, _i, _len, _ref;
      console.log('show recommanded page');
      _ref = $("#sourceList .sourceListItem");
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        dom = _ref[_i];
        $(dom).removeClass('active');
      }
      $("#recommandPageBtn").removeClass("unread");
      $('#recommandPageBtn i').hide();
      $('#homepageBtn').removeClass('active');
      $('#recommandPageBtn').addClass('active');
      this.currentPage = 'recommanded';
      return this.feedsList.showRecommandedFeeds();
    };

    Sybil.prototype.showFeedsOfSource = function(source, type) {
      var dom, listItem, _i, _len, _ref;
      if (type == null) {
        type = "normal";
      }
      console.log('show feeds in source');
      console.log(source, this.feeds[source.id]);
      $('#homepageBtn').removeClass('active');
      $('#recommandPageBtn').removeClass('active');
      $("#leftPanel .sourceListItem").removeClass('active');
      _ref = $("#leftPanel .sourceListItem");
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        dom = _ref[_i];
        if (dom.sourceObj === source) {
          listItem = dom;
        }
      }
      $(listItem).addClass("active");
      this.currentSource = source;
      this.currentPage = 'feeds';
      return this.feedsList.showFeedsOfSource(source, type);
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
          source: url
        }, function(err, res) {
          if (err) {
            console.error(err, res);
            return _this.showMessage('添加订阅失败', 'err');
          } else {
            _this.showMessage('添加成功，现在刷新页面', 'loading');
            return _this.apiGet('source', null, function(err, res) {
              _this.showMessage('完成');
              if (err) {
                console.error(err);
              }
              _this.initButtons();
              _this.sourceArr = res.data;
              _this.initSourceList();
              return _this.getFeedsOfAllSource();
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
        var feed, source, _i, _len, _ref, _results;
        console.log('mark all read btn clicked');
        _ref = _this.sourceArr;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          source = _ref[_i];
          _results.push((function() {
            var _j, _len1, _ref1, _results1;
            _ref1 = this.feeds[source.id];
            _results1 = [];
            for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
              feed = _ref1[_j];
              _results1.push(this.feedsList.markFeedAsRead(feed, source));
            }
            return _results1;
          }).call(_this));
        }
        return _results;
      };
    };

    Sybil.prototype.refresh = function() {
      var nowSourceId,
        _this = this;
      console.log('refresh!');
      if (this.currentSource) {
        nowSourceId = this.currentSource.id;
      }
      this.showMessage('正在刷新', 'loading');
      return this.apiGet('source', null, function(err, res) {
        if (err) {
          _this.showMessage('刷新失败', 'err');
          console.error(err);
          return;
        }
        _this.showMessage('完成');
        _this.initButtons();
        _this.sourceArr = res.data;
        _this.initSourceList();
        return _this.getFeedsOfAllSource(function() {
          var sourceObj, _i, _len, _ref, _results;
          if (!nowSourceId) {
            return;
          }
          _ref = _this.sourceArr;
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            sourceObj = _ref[_i];
            if (sourceObj.id === nowSourceId) {
              _this.showFeedsOfSource(sourceObj);
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
      return console.error("error! init feeditem button method has been move to feedsList.coffee");
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

    return Sybil;

  })();

  window.onload = function() {
    var sybil;
    return sybil = new Sybil;
  };

}).call(this);
