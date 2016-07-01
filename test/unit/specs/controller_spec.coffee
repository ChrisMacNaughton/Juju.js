Juju = require "src"

describe 'Juju', ->
  it 'has a controller', ->
    spyOn(window, 'WebSocket')
    juju = new Juju('10.0.4.45:17070', '')
    expect(juju.controller).toBe('10.0.4.45:17070')

  it 'has a uuid', ->
    spyOn(window, 'WebSocket')
    juju = new Juju('', '1234')
    expect(juju.uuid).toBe('1234')

  it 'connects to a websocket', ->
    spyOn(window, 'WebSocket')
    juju = new Juju('10.0.4.45:17070', '1234')
    expect(WebSocket).toHaveBeenCalledWith('wss://10.0.4.45:17070/model/1234/api')

  # it 'can login', ->
  #   spyOn(window, 'WebSocket')
  #   juju = new Juju('10.0.4.45:17070', '1234')
  #   spyOn(window, 'juju.socket.send')
  #   juju.login("Test")
  #   expect(juju.socket.send).toHaveBeenCalledWith('wss://10.0.4.45:17070/model/1234/api')
