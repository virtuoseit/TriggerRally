define [
  'jquery'
  'backbone-full'
  'cs!editor/editor'
  'cs!models/index'
], (
  $
  Backbone
  Editor
  models
) ->
  class Router extends Backbone.Router
    constructor: (@app) ->
      super()

    routes:
      "track/:trackId/edit": "trackEdit"

    trackEdit: (trackId) ->
      @app.setCurrent @app.editorView
      root = @app.root

      # This approach might be better, but doesn't fire events deeper than one layer.
      # track = models.Track.findOrCreate id: trackId
      # track.fetch
      #   success: ->
      #     root.track.set track.attributes

      # So instead we just reassign the track and fetch it in place.
      root.track = models.Track.findOrCreate id: trackId
      root.track.fetch()

  class RootModel extends models.RelModel
    models.buildProps @, [ 'track', 'user' ]
    bubbleAttribs: [ 'track', 'user' ]
    initialize: ->
      super
      @on 'all', (event) -> console.log "RootModel: \"#{event}\""

  class App
    constructor: ->
      @root = new RootModel
        user: new models.User
        track: new models.Track

      @currentView = null
      @editorView = new Editor @

      @router = new Router @

    run: ->
      xhr = new XMLHttpRequest()
      xhr.open 'GET', '/v1/auth/me'
      xhr.onload = =>
        return unless xhr.readyState is 4
        return unless xhr.status is 200
        json = JSON.parse xhr.response
        @root.user.set json.user if json.user
      xhr.send()

      Backbone.history.start pushState: yes

    setCurrent: (view) ->
      if @currentView isnt view
        @currentView?.hide()
        @currentView = view
        view?.show()
      return