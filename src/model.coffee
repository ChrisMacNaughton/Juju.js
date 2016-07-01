# Websocket = require 'websocket'
Websocket = window.Websocket

class JujuModel
  constructor: (@controller, @uuid) ->
    @socket = new WebSocket('wss://'+@controller+'/model/'+@uuid+'/api');
    @socket.onopen = @_ready
    @socket.onmessage = @_recv
    @queued_requests = []
    @pending_requests = [] # Requests that have come in
    @callbacks = {}
    @req_id = 1
    @connected = false
    @authenticated = false

    @fetched = {}
    @models = []
    @applications = []
    @servers = []
    @units = {}

    @watcher_id = undefined

  _ready: () =>
    @connected = true
    @_process_queue()


  _recv: (data) =>
    data = JSON.parse(data.data)
    @callbacks[data.RequestId](data.Response)
    delete @callbacks[data.RequestId]
    @_process_queue()

  login: (@user, @pass) ->
    msg = {
      type: 'Admin',
      request: 'Login',
      params: {
        'auth-tag': 'user-' + @user,
        credentials: @pass
      },
      version: 3
    }
    @_send msg, true, (data) =>
      @_emit('logged-in', data)
      @authenticated = true
      @_register_watcher()


  _register_watcher: () ->
    @_send {
      "Type":"Client",
      "Request":"WatchAll",
      "Version":1,
      "Params":{}
    }, false, (data) =>
      @watcher_id = data.AllWatcherId
      @_update_watcher data.AllWatcherId, @_update

  _update_watcher: (id, cb) ->
    @_send {
        "Type": "AllWatcher",
        "Request": "Next",
        "Id": id,
        "Params": {},
        "Version": 1,
       }, false, cb

  _update: (data) =>
    @_update_watcher @watcher_id, @_update
    # debugger
    if data.Deltas
      @each data.Deltas, (idx, change) =>
        @_emit(change[0] + '-' + change[1], change[2])
    else
      debugger

  _request_id: () ->
    id = @req_id
    @req_id += 1
    id

  _send: (msg, login, cb) ->
    if login || @authenticated
      @queued_requests.push([msg, cb])
    else
      @pending_requests.push([msg, cb])
    @_process_queue()

  _process_queue: () ->
    if @connected
      if @authenticated && @pending_requests.length > 0
        pending = @pending_requests
        @pending_requests = []
        @queued_requests = @queued_requests.concat(pending)
      requests = @queued_requests
      @queued_requests = []
      @each requests, (iox, parts) =>
        msg = parts[0]
        cb = parts[1]
        msg.requestId = @_request_id()
        @callbacks[msg.requestId] = cb
        @_send_to_socket(JSON.stringify(msg))


  _send_to_socket: (msg) ->
    @socket.send msg

  _emit: (name, opts) ->
    event = new CustomEvent(name, {detail: opts})

    # Dispatch/Trigger/Fire the event
    document.dispatchEvent(event);

  each: (data, cb) ->
    arrayLength = data.length
    i = 0
    while i < arrayLength
      val = data[i]
      cb(i, val)
      i++



module.exports = JujuModel
