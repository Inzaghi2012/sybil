var EasySettings = require("../lib/easysettings.js").EasySettings;
var es = new EasySettings();
es.setDefalt({name:"settings"});
var settings = es.load();
console.log(settings);
settings.conf = "conf";
es.save();
settings = es.load();
console.log(es.settings);
