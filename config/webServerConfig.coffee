feedServerConfig = require "./feedServerConfig.coffee"
exports.localPort = 40134
exports.port = 3001
exports.frontWebSocketPort = 41121
exports.feedServerPort = feedServerConfig.port
exports.feedServerHost = feedServerConfig.host
