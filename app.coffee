express = require 'express'
stylus = require 'stylus'

assets = require 'connect-assets'

less = require 'less'
fs = require 'fs'
_ = require 'underscore'

redis = null
client = null
if (process.env.REDISTOGO_URL) 
  rtg   = require("url").parse(process.env.REDISTOGO_URL)
  redis = require("redis")
  client = redis.createClient(rtg.port, rtg.hostname)
  client.auth(rtg.auth.split(":")[1])
else
  redis = require("redis")
  client = redis.createClient()

app = express.createServer()

app.use assets()

app.use express.static(__dirname + '/public')

app.use express.bodyParser()

app.set 'view engine', 'ejs'

app.get '/', (req, resp) -> resp.render 'index'

app.post '/', (req, resp) -> 

  console.log req.body
  client.incr 'nextId', (err, id) ->
    console.log 'next id : ' + id
    client.set id, JSON.stringify(req.body), (err, reply) ->
      console.log "error creating css: " + err
      resp.json({ stylesheet: id })

app.get '/less', (req, resp) -> 
  console.log 'id:' + req.param('id')
  if req.param('id') != null
    client.get req.param('id'), (err, reply) ->
      console.log err
      less_variables = ""
      values = JSON.parse(reply)
      console.log values
      _.map values, (value, key) -> 
        if(value.indexOf('#') > -1)
          less_variables += "@#{key} : #{value};\n"
        else
          less_variables += "@#{key} : #{value}px;\n"
      console.log less_variables
      fs.readFile './bootstrap/less/bootstrap.less', (err, data) ->
        console.log err
        tobeparsed = data + '\n' + less_variables
        parser = new(less.Parser)( 
          paths: ['./bootstrap/less/']
        )
        parser.parse tobeparsed, (e, tree) ->
          console.log 'parsed less'
          console.log e
          css = tree.toCSS({ compress: true })
          console.log css
          resp.send css, { 'Content-Type': 'text/css' }, 200

app.listen process.env.PORT or 3000, -> console.log 'Listening...'
