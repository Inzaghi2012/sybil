node-easysettings
=================

simple module to manage setting file/storage file for simple program 
# install
npm install easysettings
# example
Suppose it's test.js
```javascript
var EasySettings = require("../lib/easysettings.js").EasySettings;
var es = new EasySettings();
//default config save path is ./filename.conf.json
//filename is obtained from process.arvs[1] without extname
//in this case which is "test"
//or you can just set it
var es = new EasySettings("/etc/myconfig.json");

//default is useful when your script running at the first time
es.setDefalt({name:"settings"});
//if first-time running,default settings will be used 
//if not set,{} will be used
var settings = es.load();
console.log(settings);
//return value of EasySettings.load is the reference of the settings json object from easy settings
//which means you can directly modify it and save the EasySettings like below
settings.conf = "conf";
es.save();
//load again will just replace the reference
//so you should get it again
settings = es.load();
console.log(settings);
//print {name:"settings",conf:"conf"}
```