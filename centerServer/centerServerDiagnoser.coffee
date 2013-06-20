rpc = require "common-rpc"
rpc.RPCInterface.create {type:"ws",port:2013,host:"localhost",autoConfig:true},(err,inf)->
    if err
        console.error "fail to create interface"
        process.exit()
        