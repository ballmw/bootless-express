class App.BootlessView extends Backbone.View
    constructor : ( @el_id ) ->
      this.initialize()
    events : 
      'click #refresh' : 'submit'
    initialize : ->
      console.log $(@el_id).length
      @css_link_template = _.template "<link rel='stylesheet' href='/css/<%= stylesheet %>'>"
      @el = $(@el_id)[0]
      console.log (@el)
      this.render()
    render : ->
      this.delegateEvents this.events
      return this
    submit : (event) ->
      event.preventDefault()
      console.log 'submit form'
      this.getCss ( this.modifyHead )
    getCss : ( callback )->
      $('form', @el).serialize()
      $.ajax
        url: "/"
        type : 'POST'
        data : $('form', @el).serialize()
        success: callback
        dataType : 'json'
    modifyHead : (data) =>
      link = @css_link_template ({stylesheet:data.stylesheet})
      $('head').append(link)
      $('#css').attr('href', "/css/#{data.stylesheet}")
      $('#css').attr('disabled', false)
      $('#less').attr('href', "/less/#{data.stylesheet}")
      $('#less').attr('disabled', false)
