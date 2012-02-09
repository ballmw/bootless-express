express = require 'express'
stylus = require 'stylus'
assets = require 'connect-assets'
less = require 'less'
fs = require 'fs'
_ = require 'underscore'
redis  = require "redis-url".connect(process.env.REDISTOGO_URL)

app = express.createServer()
app.use assets()
app.use express.bodyParser()
client = redis.createClient(process.env.REDISTOGO_URL)

app.set 'view engine', 'ejs'
  
app.get '/', (req, resp) -> resp.render 'index'

app.post '/', (req, resp) -> 
  less_variables = ""
  console.log req.body
  _.map req.body, (value, key) -> 
    less_variables += "@#{key} : #{value};\n"
  console.log less_variables
  fs.readFile './bootstrap/less/variables.less', (err, data) ->
    console.log err
    template = data;
    fs.readFile './bootstrap/less/bootstrap.less', (err, data) ->
      console.log err
      tobeparsed = template + '\n' + data + '\n' + less_variables
      parser = new(less.Parser)( 
        paths: ['./bootstrap/less/']
      )
      parser.parse tobeparsed, (e, tree) ->
        console.log e
        css = tree.toCSS({ compress: true })
        client.incr 'nextId', (err, id) ->
          console.log 'next id : ' + id
          client.set id, css, (err, reply) ->
            console.log "error creating css: " + err
            resp.json({ stylesheet: id });

app.get '/less', (req, resp) -> 
  console.log 'id:' + req.param('id')
  if req.param('id') != null
    client.get req.param('id'), (err, reply) ->
      console.log err
      resp.send reply.toString(), { 'Content-Type': 'text/css' }, 200
    
app.listen process.env.PORT or 3000, -> console.log 'Listening...'
