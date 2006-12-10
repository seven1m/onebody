// Extension to Ajax allowing for classes of requests of which only one (the latest) is ever active at a time
// - stops queues of now-redundant requests building up / allows you to supercede one request with another easily.

// just pass in onlyLatestOfClass: 'classname' in the options of the request

Ajax.currentRequests = {};

Ajax.Responders.register({
	onCreate: function(request) {
		if (request.options.onlyLatestOfClass && Ajax.currentRequests[request.options.onlyLatestOfClass]) {
			// if a request of this class is already in progress, attempt to abort it before launching this new request
			try { Ajax.currentRequests[request.options.onlyLatestOfClass].transport.abort(); } catch(e) {}
		}
		// keep note of this request object so we can cancel it if superceded
		Ajax.currentRequests[request.options.onlyLatestOfClass] = request;
	},
	onComplete: function(request) {
		if (request.options.onlyLatestOfClass) {
			// remove the request from our cache once completed so it can be garbage collected
			Ajax.currentRequests[request.options.onlyLatestOfClass] = null;
		}
	}
});
