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

app.get '/', (req, res) -> res.render 'index'

app.post '/', (req, res) -> 
  less_variables = ""

  _.map req.body, (value, key) -> 
    if(value.indexOf('#') > -1)
      less_variables += "@#{key} : #{value};\n"
    else
      less_variables += "@#{key} : #{value}px;\n"

  console.log less_variables
  putless less_variables, (err, id) ->
    res.json({ stylesheet: id });

app.get '/css/:id', (req, res) -> 
  id = req.params.id

  if id != null
    getless id, (err, less) ->
      logiferr "Unable to get less", err

      bootless = new Bootless
      bootless.init()

      bootless.boot less, (css)-> 
        res.send css.toString(), { 'Content-Type': 'text/css' }, 200

app.get '/less/:id', (req, res) ->
  id = req.params.id

  if( id != null )
    getless id, (err, less) ->
      res.send less, { 'Content-Type': 'text/css' }, 200

putless = (less, callback) ->
  client.incr 'nextId', (err, id) ->
    console.log 'next id : ' + id
    client.set id, less, (err, reply) ->
      callback err, id

getless = (id, callback) ->
  client.get id, callback

logiferr = (message, err) ->
  if( err != null )
    console.log message + ": " + err 

class Bootless
  variables = ""
  bootstrap = ""

  init: ->
    fs.readFile './bootstrap/less/variables.less', (err, data) ->
      logiferr 'Unable to load variables.less', err
      variables = data

   fs.readFile './bootstrap/less/bootstrap.less', (err, data) ->
      logiferr 'Unable to load bootstrap.less', err
      bootstrap = data

  boot: (lesscss, callback) ->
    tobeparsed = variables + '\n' + bootstrap + '\n' + lesscss
    parser = new(less.Parser)( 
      paths: ['./bootstrap/less/']
    )
    parser.parse tobeparsed, (e, tree) ->
      logiferr 'Unable to parse less', e
      css = tree.toCSS({ compress: true })

      callback( css )
    
app.listen process.env.PORT or 3000, -> console.log 'Listening...'