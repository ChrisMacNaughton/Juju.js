# Copyright: Hiroshi Ichikawa <http://gimite.net/en/>
# License: New BSD License
# Reference: http://dev.w3.org/html5/websockets/
# Reference: http://tools.ietf.org/html/rfc6455
do ->
  if window.WebSocket
    return
  else if window.MozWebSocket
    # Firefox.
    window.WebSocket = MozWebSocket
    return
  logger = undefined
  if window.WEB_SOCKET_LOGGER
    logger = WEB_SOCKET_LOGGER
  else if window.console and window.console.log and window.console.error
    # In some environment, console is defined but console.log or console.error is missing.
    logger = window.console
  else
    logger =
      log: ->
      error: ->

  ###*
  # Our own implementation of WebSocket class using Flash.
  # @param {string} url
  # @param {array or string} protocols
  # @param {string} proxyHost
  # @param {int} proxyPort
  # @param {string} headers
  ###

  window.WebSocket = (url, protocols, proxyHost, proxyPort, headers) ->
    self = this
    self.__id = WebSocket.__nextId++
    WebSocket.__instances[self.__id] = self
    self.readyState = WebSocket.CONNECTING
    self.bufferedAmount = 0
    self.__events = {}
    if !protocols
      protocols = []
    else if typeof protocols == 'string'
      protocols = [ protocols ]
    # Uses setTimeout() to make sure __createFlash() runs after the caller sets ws.onopen etc.
    # Otherwise, when onopen fires immediately, onopen is called before it is set.
    self.__createTask = setTimeout((->
      WebSocket.__addTask ->
        self.__createTask = null
        WebSocket.__flash.create self.__id, url, protocols, proxyHost or null, proxyPort or 0, headers or null
        return
      return
    ), 0)
    return

  ###*
  # Send data to the web socket.
  # @param {string} data  The data to send to the socket.
  # @return {boolean}  True for success, false for failure.
  ###

  WebSocket::send = (data) ->
    if @readyState == WebSocket.CONNECTING
      throw 'INVALID_STATE_ERR: Web Socket connection has not been established'
    # We use encodeURIComponent() here, because FABridge doesn't work if
    # the argument includes some characters. We don't use escape() here
    # because of this:
    # https://developer.mozilla.org/en/Core_JavaScript_1.5_Guide/Functions#escape_and_unescape_Functions
    # But it looks decodeURIComponent(encodeURIComponent(s)) doesn't
    # preserve all Unicode characters either e.g. "\uffff" in Firefox.
    # Note by wtritch: Hopefully this will not be necessary using ExternalInterface.  Will require
    # additional testing.
    result = WebSocket.__flash.send(@__id, encodeURIComponent(data))
    if result < 0
      # success
      true
    else
      @bufferedAmount += result
      false

  ###*
  # Close this web socket gracefully.
  ###

  WebSocket::close = ->
    if @__createTask
      clearTimeout @__createTask
      @__createTask = null
      @readyState = WebSocket.CLOSED
      return
    if @readyState == WebSocket.CLOSED or @readyState == WebSocket.CLOSING
      return
    @readyState = WebSocket.CLOSING
    WebSocket.__flash.close @__id
    return

  ###*
  # Implementation of {@link <a href="http://www.w3.org/TR/DOM-Level-2-Events/events.html#Events-registration">DOM 2 EventTarget Interface</a>}
  #
  # @param {string} type
  # @param {function} listener
  # @param {boolean} useCapture
  # @return void
  ###

  WebSocket::addEventListener = (type, listener, useCapture) ->
    if !(type of @__events)
      @__events[type] = []
    @__events[type].push listener
    return

  ###*
  # Implementation of {@link <a href="http://www.w3.org/TR/DOM-Level-2-Events/events.html#Events-registration">DOM 2 EventTarget Interface</a>}
  #
  # @param {string} type
  # @param {function} listener
  # @param {boolean} useCapture
  # @return void
  ###

  WebSocket::removeEventListener = (type, listener, useCapture) ->
    if !(type of @__events)
      return
    events = @__events[type]
    i = events.length - 1
    while i >= 0
      if events[i] == listener
        events.splice i, 1
        break
      --i
    return

  ###*
  # Implementation of {@link <a href="http://www.w3.org/TR/DOM-Level-2-Events/events.html#Events-registration">DOM 2 EventTarget Interface</a>}
  #
  # @param {Event} event
  # @return void
  ###

  WebSocket::dispatchEvent = (event) ->
    events = @__events[event.type] or []
    i = 0
    while i < events.length
      events[i] event
      ++i
    handler = @['on' + event.type]
    if handler
      handler.apply this, [ event ]
    return

  WebSocket::__createSimpleEvent = (type) ->
    if document.createEvent and window.Event
      event = document.createEvent('Event')
      event.initEvent type, false, false
      event
    else
      {
        type: type
        bubbles: false
        cancelable: false
      }

  WebSocket::__createMessageEvent = (type, data) ->
    if window.MessageEvent and typeof MessageEvent == 'function' and !window.opera
      new MessageEvent('message',
        'view': window
        'bubbles': false
        'cancelable': false
        'data': data)
    else if document.createEvent and window.MessageEvent and !window.opera
      event = document.createEvent('MessageEvent')
      event.initMessageEvent 'message', false, false, data, null, null, window, null
      event
    else
      # Old IE and Opera, the latter one truncates the data parameter after any 0x00 bytes.
      {
        type: type
        data: data
        bubbles: false
        cancelable: false
      }

  ###*
  # Define the WebSocket readyState enumeration.
  ###

  WebSocket.CONNECTING = 0
  WebSocket.OPEN = 1
  WebSocket.CLOSING = 2
  WebSocket.CLOSED = 3
  # Field to check implementation of WebSocket.
  WebSocket.__isFlashImplementation = false
  WebSocket.__initialized = false
  WebSocket.__flash = null
  WebSocket.__instances = {}
  WebSocket.__tasks = []
  WebSocket.__nextId = 0


  WebSocket.__addTask = (task) ->
    if WebSocket.__flash
      task()
    else
      WebSocket.__tasks.push task
    return

