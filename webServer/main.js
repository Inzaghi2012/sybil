// Generated by CoffeeScript 1.6.1
(function() {
  var app, async, crypto, db, error, express, mongodb, path, rssFetcher, settings, utils;

  mongodb = require("mongodb");

  require("coffee-script");

  express = require("express");

  async = require("async");

  crypto = require("crypto");

  path = require("path");

  settings = require("./settings.coffee");

  db = require("./db.coffee");

  utils = require("./utils.coffee");

  error = require("./error.coffee");

  rssFetcher = require("../crawler/rssFetcher.coffee");

  app = express();

  app.enable("trust proxy");

  app.use(express.bodyParser());

  app.use(express.cookieParser());

  app.use(function(req, res, next) {
    if (!db.DatabaseReady) {
      res.status(503);
      res.json({
        "error": "Server Not Ready"
      });
      return;
    }
    return next();
  });

  app.use(error.StandardJsonReply());

  app._method = app.get;

  app._method("/api/subscribe", function(req, res) {
    var rss;
    rss = req.param("rss", null);
    if (!rss) {
      res.invalidParameter();
      return;
    }
    return db.Collections.rss.findOne({
      _id: rss
    }, function(err, item) {
      if (err) {
        res.serverError();
        return;
      }
      if (!item) {
        return utils.addRss(rss, function(err, rssInfo) {
          if (err) {
            res.serverError();
          } else {
            res.success(rssInfo);
          }
        });
      } else {
        res.alreadyExists();
      }
    });
  });

  app._method("/api/unsubscribe", function(req, res) {
    var rss;
    rss = req.param("rss", null);
    if (!rss) {
      res.invalidParameter();
      return;
    }
    return db.Collections.rss.findOne({
      _id: rss
    }, function(err, item) {
      if (err) {
        res.serverError();
        return;
      }
      if (!item) {
        res.notFound();
        return;
      }
      console.log("~~~");
      db.Collections.rss.remove({
        _id: rss
      });
      return res.success();
    });
  });

  app._method("/api/rss", function(req, res) {
    var cursor;
    cursor = db.Collections.rss.find();
    return cursor.toArray(function(err, rsses) {
      var rssInfos;
      if (err) {
        res.serverError();
        return;
      }
      if (!rsses) {
        rsses = [];
      }
      rssInfos = rsses.map(function(item) {
        return {
          id: item.id,
          title: item.meta.title || null,
          date: item.meta.date || null,
          link: item.meta.link,
          description: item.meta.description
        };
      });
      return res.success(rssInfos);
    });
  });

  app._method("/api/feed", function(req, res) {
    var count, cursor, query, rss, start, type;
    rss = req.param("rss", null);
    start = req.param("start", null);
    type = req.param("type", null);
    if (!start) {
      start = 0;
    }
    count = req.param("count", null);
    if (!count) {
      count = 10;
    }
    if (!rss) {
      res.invalidParameter();
      return;
    }
    rss = rss.trim();
    query = {
      source: rss
    };
    if (type !== "all") {
      query.read = {
        $exists: false
      };
    }
    cursor = db.Collections.feed.find(query, {
      skip: start,
      limit: count,
      sort: "date"
    });
    cursor.toArray(function(err, arrs) {
      var result;
      result = {};
      if (err) {
        res.serverError();
        return;
      }
      if (arrs.length !== count) {
        result.drain = true;
      }
      result.articles = arrs;
      res.success(result);
    });
    return res.success();
  });

  app._method("/api/recommand", function(req, res) {
    return res.success();
  });

  app._method("/api/read", function(req, res) {
    return res / success();
  });

  app._method("/api/unreadFeed", function(req, res) {
    return res / success();
  });

  app._method("/api/like", function(req, res) {
    return res / success();
  });

  app._method("/api/unlike", function(req, res) {
    return res / success();
  });

  app._method("/api/share", function(req, res) {
    return res / success();
  });

  app._method("/api/unlike", function(req, res) {
    return res / success();
  });

  app.all("/api/:apiname", function(req, res, next) {
    res.status(404);
    return res.jsonError("Api Not Found", Error.NotFound);
  });

  app.get("/*", express["static"]("/srv/sybil/static/"));

  app.all("/*", function(req, res, next) {
    res.status(404);
    return res.end("404 :(");
  });

  app.listen(3001);

}).call(this);
