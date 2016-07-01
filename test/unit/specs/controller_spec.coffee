Juju = require "src"

describe 'JujuModel', ->
  it 'has a controller', ->
    spyOn(window, 'WebSocket')
    juju = new Juju.model('10.0.4.45:17070', '')
    expect(juju.controller).toBe('10.0.4.45:17070')

  it 'has a uuid', ->
    spyOn(window, 'WebSocket')
    juju = new Juju.model('', '1234')
    expect(juju.uuid).toBe('1234')

  it 'connects to a websocket', ->
    spyOn(window, 'WebSocket')
    juju = new Juju.model('10.0.4.45:17070', '1234')
    expect(WebSocket).toHaveBeenCalledWith('wss://10.0.4.45:17070/model/1234/api')

  it 'can login', ->
    spyOn(window, 'WebSocket')
    juju = new Juju.model('10.0.4.45:17070', '1234')
    juju.connected = true
    spyOn(juju, '_send_to_socket')
    juju.login("Test")
    expect(juju._send_to_socket).toHaveBeenCalledWith('{"type":"Admin","request":"Login","params":{"auth-tag":"user-Test"},"version":3,"requestId":1}')
