var path = require("path");
var fs = require("fs");
var EasySettings = function(settingPath,settings){
    var callPath = process.argv[1];
    var top = module;
    while(top.parent)top=top.parent;
    var mainPath = top.filename
    // \\ if for escape of .ext dot,which means any char.
    this.settingPath = settingPath || mainPath.substring(0,mainPath.length-path.extname(mainPath).length)+".conf.json";
    this.setDefault(settings||{});
    this.settings = {};
}
EasySettings.prototype.setDefault = function(settings){
    this.defaultSettings = settings;
}
EasySettings.prototype.save = function(settingPath){
    this.settingPath = settingPath || this.settingPath;
    fs.writeFileSync(this.settingPath,JSON.stringify(this.settings))
    return true;
}
EasySettings.prototype.load = function(settingPath){
    this.settingPath = settingPath || this.settingPath;
    try{
	var settings = JSON.parse(fs.readFileSync(this.settingPath));
    }catch(e){
	var settings = this.defaultSettings;
    }finally{
	this.settings = settings;
	return this.settings;
    }
}
exports.EasySettings = EasySettings;
