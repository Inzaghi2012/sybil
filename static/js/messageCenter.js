// Generated by CoffeeScript 1.6.1
(function() {
  var MessageCenter,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  MessageCenter = (function(_super) {

    __extends(MessageCenter, _super);

    function MessageCenter(port) {
      MessageCenter.__super__.constructor.call(this);
      this.port = port;
      this.connect();
    }

    MessageCenter.prototype.connect = function() {
      var ws,
        _this = this;
      ws = new WebSocket("ws://" + window.location.hostname + ":" + this.port);
      ws.onopen = function() {
        return _this.emit("connect");
      };
      ws.onmessage = function(message) {
        return _this.handleMessage(message.data);
      };
      ws.onclose = function() {
        _this.emit("disconnect");
        return _this.connect();
      };
      return this.ws = ws;
    };

    MessageCenter.prototype.send = function(data) {
      return this.ws.send(JSON.stringify(data));
    };

    MessageCenter.prototype.handleMessage = function(msg) {
      var data;
      try {
        data = JSON.parse(msg);
      } catch (e) {
        console.log("fail to parse msg", msg);
      }
      return this.dispatch(data);
    };

    MessageCenter.prototype.dispatch = function(data) {
      return this.emit(data.type, data.value);
    };

    return MessageCenter;

  })(Leaf.EventEmitter);

  window.MessageCenter = MessageCenter;

}).call(this);
