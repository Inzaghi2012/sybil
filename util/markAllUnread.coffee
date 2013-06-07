db = require "../server/db.coffee"
db.ready ()->
    db.Collections.feed.update {read:true},{$unset:{read:1}},{multi:true}
    db.close()
    console.log "done"