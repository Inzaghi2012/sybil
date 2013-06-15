require "coffee-script"
Error = {
    ServerError:0
    InvalidParameter:1
    AlreadyExists:2
    AuthorizationFailed:3
    NotFound:4
    UnknownFormat:5
    Fail:6
}
exports.StandardJsonReply = ()->
    return (req,res,next)->
        res.json = (obj)->
            if not res.responseContentType
                res.setHeader("Content-Type","text/json")
            else
                res.setHeader("Content-Type",res.responseContentType)
            #if simulateDelay
            #    setTimeout (()-> 
            #        res.end(JSON.stringify(obj))
            #    ),delayTime
            #    return
            res.end(JSON.stringify(obj))
        res.success = (obj)->
            res.json {state:true,data:obj}
        res.jsonError = (description,errorCode,subCode)->
            @json({
                state:false
                error:description
                errorCode:errorCode #Abstract general error code
                subCode:subCode #detail error code used for custom Error
                })
        
        res.serverError = ()->
            res.jsonError "Server Error",Error.ServerError
        res.invalidParameter = ()->
            res.jsonError "Invalid Parameter",Error.InvalidParameter
        res.alreadyExists = ()->
            res.jsonError "Already Exists",Error.AlreadyExists

        res.notFound = ()->
            res.jsonError "Not Found",Error.NotFound
        next()
exports.Error = Error
exports.StandardJsonReply