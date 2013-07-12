# RSS Format
Rss
```coffee-script
title:title or null
description:description or null
link:link # point to real source site
source:RSSurl # base64 primary key _id used when search
auther: auther or null
language: language or null
favicon:favicon or null
============= extra info computed by server ==================
unreadCount:how many unread.
```
feed
``` coffee-script
title:article.title
link:article.link
source:RSSurl
author:article.author
date:article.date
guid:article.guid
summary:article.summary or article.title
description:article.description or article.title
============== extra info computed by server  ================
id:@url+article.guid
read:isRead #true or undefined(false), is this feed read?
```
