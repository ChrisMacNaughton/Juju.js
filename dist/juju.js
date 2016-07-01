(function webpackUniversalModuleDefinition(root, factory) {
	if(typeof exports === 'object' && typeof module === 'object')
		module.exports = factory();
	else if(typeof define === 'function' && define.amd)
		define([], factory);
	else if(typeof exports === 'object')
		exports["Juju"] = factory();
	else
		root["Juju"] = factory();
})(this, function() {
return /******/ (function(modules) { // webpackBootstrap
/******/ 	// The module cache
/******/ 	var installedModules = {};
/******/
/******/ 	// The require function
/******/ 	function __webpack_require__(moduleId) {
/******/
/******/ 		// Check if module is in cache
/******/ 		if(installedModules[moduleId])
/******/ 			return installedModules[moduleId].exports;
/******/
/******/ 		// Create a new module (and put it into the cache)
/******/ 		var module = installedModules[moduleId] = {
/******/ 			exports: {},
/******/ 			id: moduleId,
/******/ 			loaded: false
/******/ 		};
/******/
/******/ 		// Execute the module function
/******/ 		modules[moduleId].call(module.exports, module, module.exports, __webpack_require__);
/******/
/******/ 		// Flag the module as loaded
/******/ 		module.loaded = true;
/******/
/******/ 		// Return the exports of the module
/******/ 		return module.exports;
/******/ 	}
/******/
/******/
/******/ 	// expose the modules object (__webpack_modules__)
/******/ 	__webpack_require__.m = modules;
/******/
/******/ 	// expose the module cache
/******/ 	__webpack_require__.c = installedModules;
/******/
/******/ 	// __webpack_public_path__
/******/ 	__webpack_require__.p = "";
/******/
/******/ 	// Load entry module and return exports
/******/ 	return __webpack_require__(0);
/******/ })
/************************************************************************/
/******/ ([
/* 0 */
/***/ function(module, exports) {

	var Juju, Websocket;
	
	Websocket = window.Websocket;
	
	Juju = (function() {
	  function Juju(controller, uuid) {
	    this.controller = controller;
	    this.uuid = uuid;
	    this.socket = new WebSocket('wss://' + this.controller + '/model/' + this.uuid + '/api');
	    this.socket.onopen = this._ready;
	    this.queued_requests = [];
	    this.req_id = 1;
	  }
	
	  Juju.prototype._ready = function() {
	    return this.connected = true;
	  };
	
	  Juju.prototype.login = function(user, pass) {
	    var msg;
	    this.user = user;
	    this.pass = pass;
	    msg = {
	      type: 'Admin',
	      request: 'Login',
	      params: {
	        'auth-tag': 'user-' + this.user,
	        credentials: this.pass
	      },
	      version: 3,
	      requestId: this._request_id()
	    };
	    debugger;
	  };
	
	  Juju.prototype._request_id = function() {
	    var id;
	    id = this.req_id;
	    this.req_id += 1;
	    return id;
	  };
	
	  Juju.prototype._send = function(msg) {
	    return this.socket.send(JSON.stringify(msg));
	  };
	
	  return Juju;
	
	})();
	
	module.exports = Juju;


/***/ }
/******/ ])
});
;
//# sourceMappingURL=juju.js.map