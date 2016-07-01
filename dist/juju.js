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
/***/ function(module, exports, __webpack_require__) {

	var Juju, JujuModel;
	
	JujuModel = __webpack_require__(2);
	
	Juju = {
	  model: JujuModel
	};
	
	module.exports = Juju;


/***/ },
/* 1 */,
/* 2 */
/***/ function(module, exports) {

	var JujuModel, Websocket,
	  bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
	
	Websocket = window.Websocket;
	
	JujuModel = (function() {
	  function JujuModel(controller, uuid) {
	    this.controller = controller;
	    this.uuid = uuid;
	    this._update = bind(this._update, this);
	    this._recv = bind(this._recv, this);
	    this._ready = bind(this._ready, this);
	    this.socket = new WebSocket('wss://' + this.controller + '/model/' + this.uuid + '/api');
	    this.socket.onopen = this._ready;
	    this.socket.onmessage = this._recv;
	    this.queued_requests = [];
	    this.pending_requests = [];
	    this.callbacks = {};
	    this.req_id = 1;
	    this.connected = false;
	    this.authenticated = false;
	    this.fetched = {};
	    this.models = [];
	    this.applications = [];
	    this.servers = [];
	    this.units = {};
	    this.watcher_id = void 0;
	  }
	
	  JujuModel.prototype._ready = function() {
	    this.connected = true;
	    return this._process_queue();
	  };
	
	  JujuModel.prototype._recv = function(data) {
	    data = JSON.parse(data.data);
	    this.callbacks[data.RequestId](data.Response);
	    delete this.callbacks[data.RequestId];
	    return this._process_queue();
	  };
	
	  JujuModel.prototype.login = function(user, pass) {
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
	      version: 3
	    };
	    return this._send(msg, true, (function(_this) {
	      return function(data) {
	        _this._emit('logged-in', data);
	        _this.authenticated = true;
	        return _this._register_watcher();
	      };
	    })(this));
	  };
	
	  JujuModel.prototype._register_watcher = function() {
	    return this._send({
	      "Type": "Client",
	      "Request": "WatchAll",
	      "Version": 1,
	      "Params": {}
	    }, false, (function(_this) {
	      return function(data) {
	        _this.watcher_id = data.AllWatcherId;
	        return _this._update_watcher(data.AllWatcherId, _this._update);
	      };
	    })(this));
	  };
	
	  JujuModel.prototype._update_watcher = function(id, cb) {
	    return this._send({
	      "Type": "AllWatcher",
	      "Request": "Next",
	      "Id": id,
	      "Params": {},
	      "Version": 1
	    }, false, cb);
	  };
	
	  JujuModel.prototype._update = function(data) {
	    this._update_watcher(this.watcher_id, this._update);
	    if (data.Deltas) {
	      return this.each(data.Deltas, (function(_this) {
	        return function(idx, change) {
	          return _this._emit(change[0] + '-' + change[1], change[2]);
	        };
	      })(this));
	    } else {
	      debugger;
	    }
	  };
	
	  JujuModel.prototype._request_id = function() {
	    var id;
	    id = this.req_id;
	    this.req_id += 1;
	    return id;
	  };
	
	  JujuModel.prototype._send = function(msg, login, cb) {
	    if (login || this.authenticated) {
	      this.queued_requests.push([msg, cb]);
	    } else {
	      this.pending_requests.push([msg, cb]);
	    }
	    return this._process_queue();
	  };
	
	  JujuModel.prototype._process_queue = function() {
	    var pending, requests;
	    if (this.connected) {
	      if (this.authenticated && this.pending_requests.length > 0) {
	        pending = this.pending_requests;
	        this.pending_requests = [];
	        this.queued_requests = this.queued_requests.concat(pending);
	      }
	      requests = this.queued_requests;
	      this.queued_requests = [];
	      return this.each(requests, (function(_this) {
	        return function(iox, parts) {
	          var cb, msg;
	          msg = parts[0];
	          cb = parts[1];
	          msg.requestId = _this._request_id();
	          _this.callbacks[msg.requestId] = cb;
	          return _this._send_to_socket(JSON.stringify(msg));
	        };
	      })(this));
	    }
	  };
	
	  JujuModel.prototype._send_to_socket = function(msg) {
	    return this.socket.send(msg);
	  };
	
	  JujuModel.prototype._emit = function(name, opts) {
	    var event;
	    event = new CustomEvent(name, {
	      detail: opts
	    });
	    return document.dispatchEvent(event);
	  };
	
	  JujuModel.prototype.each = function(data, cb) {
	    var arrayLength, i, results, val;
	    arrayLength = data.length;
	    i = 0;
	    results = [];
	    while (i < arrayLength) {
	      val = data[i];
	      cb(i, val);
	      results.push(i++);
	    }
	    return results;
	  };
	
	  return JujuModel;
	
	})();
	
	module.exports = JujuModel;


/***/ }
/******/ ])
});
;
//# sourceMappingURL=juju.js.map