# Websocket = require 'websocket'
Websocket = window.Websocket

class Juju
  constructor: (@controller, @uuid) ->
    @socket = new WebSocket('wss://'+@controller+'/model/'+@uuid+'/api');
    @socket.onopen = @_ready
    @queued_requests = []
    @req_id = 1;

  _ready: () ->
    @connected = true

  login: (@user, @pass) ->
    msg = {
      type: 'Admin',
      request: 'Login',
      params: {
        'auth-tag': 'user-' + @user,
        credentials: @pass
      },
      version: 3,
      requestId: @_request_id()
    }
    debugger


  _request_id: () ->
    id = @req_id
    @req_id += 1
    id

  _send: (msg) ->
    @socket.send(JSON.stringify(msg))

module.exports = Juju
