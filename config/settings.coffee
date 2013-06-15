path = require("path")
_ = {}
_.root = "/srv/sybil/"
_.userImageDirectory = path.join _.root,"static/image"
_.userAudioDirectory = path.join _.root,"static/audio"
_.userThumbDirectory = path.join _.root,"static/thumb"
_.userVideoDirectory = path.join _.root,"static/video"
_.utilDirectory = path.join _.root,"util"
_.videoUrlSupport = [
    /http:\/\/www.bilibili.tv\/video\/av[0-9]+/i,
    /http:\/\/www.youtube.com\/watch?v=[-0-9a-z]/i
]

_.database = {
    "name":"sybil"
    "host":"localhost"
    "port":27017
    "option":{}
}
_.salt = "!@$#%!@#HatsuneDaisuki{raw}ToPreventACrack!@#%!@$#@^)+{:@#F!@$"
_.defaultExpire = 31*24*60*60*1000
_.sessionSecret = "HatsuneDaisuki"
exports.settings = _