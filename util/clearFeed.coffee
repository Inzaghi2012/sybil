db = require "../server/db.coffee"
db.ready ()->
    db.Collections.feed.remove()
    db.close()
    console.log "done"