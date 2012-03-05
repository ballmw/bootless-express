  $ = require('jquery')
  jQuery = $
  jsdom    = require("jsdom").jsdom
  assert = require('assert')
  require('../assets/js/bootless.coffee')

  setFixtures = (fixture) ->
    $('body').html(fixture)

  describe "BootlessView", ->
    describe "Loads the template", ->
      beforeEach ->
        setFixtures(
          """
          <div id="bootless">The bootless div.</div>
          <stylesheet type="text/template" id="css_link_template">This will be a link in the header.</script>
          """
        )
        @view = new App.BootlessView('#bootless','#css_link_template')
      it "loads the css template", ->
        expect(@view.css_link_template).toBeDefined()

      it "is a DIV", ->
        expect(@view.el.nodeName).toEqual("DIV")

      it "returns the view object", ->
        expect(this.view.render()).toEqual(this.view)
        
    describe "Submit state", ->
      describe "When submit button handler fired - Jasmine async", ->
        view = null
        beforeEach ->
          spyOn($, "ajax").andCallFake (options) ->
            options.success()
            
          setFixtures (
            """
            <head>
            <link id="bootstrap" rel="stylesheet" media="screen" href="replaceme.css">
            </head>
            <div id="bootless">
              <form><input type="submit"></form>
            </div>
            <script type="text/template" id="css_link_template">This will be a link in the header.</script>
            """ )
          view = new App.BootlessView('#bootless','#css_link_template')

        it "posts to the server", ->
          callback = jasmine.createSpy()
          view.getCss(callback)
          expect(callback).toHaveBeenCalled()
        it "uses the new css in the head element", ->
          view.modifyHead('abc')
          
