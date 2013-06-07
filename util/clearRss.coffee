db = require "../server/db.coffee"
db.ready ()->
    db.Collections.rss.remove()
    db.close()
    console.log "done"