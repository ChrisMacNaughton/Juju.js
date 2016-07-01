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
  if location.protocol == 'file:'
    logger.error 'WARNING: web-socket-js doesn\'t work in file:///... URL ' + 'unless you set Flash Security Settings properly. ' + 'Open the page via Web server i.e. http://...'

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

  ###*
  # Handles an event from Flash.
  # @param {Object} flashEvent
  ###

  WebSocket::__handleEvent = (flashEvent) ->
    if 'readyState' of flashEvent
      @readyState = flashEvent.readyState
    if 'protocol' of flashEvent
      @protocol = flashEvent.protocol
    jsEvent = undefined
    if flashEvent.type == 'open' or flashEvent.type == 'error'
      jsEvent = @__createSimpleEvent(flashEvent.type)
    else if flashEvent.type == 'close'
      jsEvent = @__createSimpleEvent('close')
      jsEvent.wasClean = if flashEvent.wasClean then true else false
      jsEvent.code = flashEvent.code
      jsEvent.reason = flashEvent.reason
    else if flashEvent.type == 'message'
      data = decodeURIComponent(flashEvent.message)
      jsEvent = @__createMessageEvent('message', data)
    else
      throw 'unknown event type: ' + flashEvent.type
    @dispatchEvent jsEvent
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
  WebSocket.__isFlashImplementation = true
  WebSocket.__initialized = false
  WebSocket.__flash = null
  WebSocket.__instances = {}
  WebSocket.__tasks = []
  WebSocket.__nextId = 0

  ###*
  # Load a new flash security policy file.
  # @param {string} url
  ###

  WebSocket.loadFlashPolicyFile = (url) ->
    WebSocket.__addTask ->
      WebSocket.__flash.loadManualPolicyFile url
      return
    return

  ###*
  # Loads WebSocketMain.swf and creates WebSocketMain object in Flash.
  ###

  WebSocket.__initialize = ->
    if WebSocket.__initialized
      return
    WebSocket.__initialized = true
    if WebSocket.__swfLocation
      # For backword compatibility.
      window.WEB_SOCKET_SWF_LOCATION = WebSocket.__swfLocation
    if !window.WEB_SOCKET_SWF_LOCATION
      logger.error '[WebSocket] set WEB_SOCKET_SWF_LOCATION to location of WebSocketMain.swf'
      return
    if !window.WEB_SOCKET_SUPPRESS_CROSS_DOMAIN_SWF_ERROR and !WEB_SOCKET_SWF_LOCATION.match(/(^|\/)WebSocketMainInsecure\.swf(\?.*)?$/) and WEB_SOCKET_SWF_LOCATION.match(/^\w+:\/\/([^\/]+)/)
      swfHost = RegExp.$1
      if location.host != swfHost
        logger.error '[WebSocket] You must host HTML and WebSocketMain.swf in the same host ' + '(\'' + location.host + '\' != \'' + swfHost + '\'). ' + 'See also \'How to host HTML file and SWF file in different domains\' section ' + 'in README.md. If you use WebSocketMainInsecure.swf, you can suppress this message ' + 'by WEB_SOCKET_SUPPRESS_CROSS_DOMAIN_SWF_ERROR = true;'
    container = document.createElement('div')
    container.id = 'webSocketContainer'
    # Hides Flash box. We cannot use display: none or visibility: hidden because it prevents
    # Flash from loading at least in IE. So we move it out of the screen at (-100, -100).
    # But this even doesn't work with Flash Lite (e.g. in Droid Incredible). So with Flash
    # Lite, we put it at (0, 0). This shows 1x1 box visible at left-top corner but this is
    # the best we can do as far as we know now.
    container.style.position = 'absolute'
    if WebSocket.__isFlashLite()
      container.style.left = '0px'
      container.style.top = '0px'
    else
      container.style.left = '-100px'
      container.style.top = '-100px'
    holder = document.createElement('div')
    holder.id = 'webSocketFlash'
    container.appendChild holder
    document.body.appendChild container
    # See this article for hasPriority:
    # http://help.adobe.com/en_US/as3/mobile/WS4bebcd66a74275c36cfb8137124318eebc6-7ffd.html
    swfobject.embedSWF WEB_SOCKET_SWF_LOCATION, 'webSocketFlash', '1', '1', '10.0.0', null, null, {
      hasPriority: true
      swliveconnect: true
      allowScriptAccess: 'always'
    }, null, (e) ->
      if !e.success
        logger.error '[WebSocket] swfobject.embedSWF failed'
      return
    return

  ###*
  # Called by Flash to notify JS that it's fully loaded and ready
  # for communication.
  ###

  WebSocket.__onFlashInitialized = ->
    # We need to set a timeout here to avoid round-trip calls
    # to flash during the initialization process.
    setTimeout (->
      WebSocket.__flash = document.getElementById('webSocketFlash')
      WebSocket.__flash.setCallerUrl location.href
      WebSocket.__flash.setDebug ! !window.WEB_SOCKET_DEBUG
      i = 0
      while i < WebSocket.__tasks.length
        WebSocket.__tasks[i]()
        ++i
      WebSocket.__tasks = []
      return
    ), 0
    return

  ###*
  # Called by Flash to notify WebSockets events are fired.
  ###

  WebSocket.__onFlashEvent = ->
    setTimeout (->
      try
        # Gets events using receiveEvents() instead of getting it from event object
        # of Flash event. This is to make sure to keep message order.
        # It seems sometimes Flash events don't arrive in the same order as they are sent.
        events = WebSocket.__flash.receiveEvents()
        i = 0
        while i < events.length
          WebSocket.__instances[events[i].webSocketId].__handleEvent events[i]
          ++i
      catch e
        logger.error e
      return
    ), 0
    true

  # Called by Flash.

  WebSocket.__log = (message) ->
    logger.log decodeURIComponent(message)
    return

  # Called by Flash.

  WebSocket.__error = (message) ->
    logger.error decodeURIComponent(message)
    return

  WebSocket.__addTask = (task) ->
    if WebSocket.__flash
      task()
    else
      WebSocket.__tasks.push task
    return

  ###*
  # Test if the browser is running flash lite.
  # @return {boolean} True if flash lite is running, false otherwise.
  ###

  WebSocket.__isFlashLite = ->
    if !window.navigator or !window.navigator.mimeTypes
      return false
    mimeType = window.navigator.mimeTypes['application/x-shockwave-flash']
    if !mimeType or !mimeType.enabledPlugin or !mimeType.enabledPlugin.filename
      return false
    if mimeType.enabledPlugin.filename.match(/flashlite/i) then true else false

  if !window.WEB_SOCKET_DISABLE_AUTO_INITIALIZATION
    # NOTE:
    #   This fires immediately if web_socket.js is dynamically loaded after
    #   the document is loaded.
    swfobject.addDomLoadEvent ->
      WebSocket.__initialize()
      return
  return

# module.exports = Websocket
