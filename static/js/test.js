(function() {

  $(function() {
    var factory;
    factory = new Leaf.ApiFactory();
    factory.path = "api/";
    factory.defaultMethod = "GET";
    factory.declare("authedNodes", []);
    factory.declare("sendMessage", ["guid", "message"]);
    window.API = factory.build();
    window.km = new Leaf.KeyEventManager;
    window.km.attachTo(window);
    window.km.master();
    window.km.on("keydown", function(e) {
      if (e.which === Leaf.Key.s && e.altKey) {
        e.capture();
        return window.authedNodeList.toggle();
      }
    });
    window._msgCenter = new MessageCenter(41123);
    return window._msgCenter.on("message", function(data) {
      return alert(data.who.pubkey);
    });
  });

}).call(this);
