var http = require('http');
var httpProxy = require('http-proxy');

//proxy standard http requests
var proxy = new httpProxy.createProxyServer({});

var server = http.createServer(function(req, res) {
  console.log('req received');

  proxy.web(req, res, { target: 'http://localhost:8000' });


});
  
//upgrade on websocket
server.on('upgrade', function(req, socket, head) {
  proxy.ws(
    req, 
    socket, 
    head,
    { target: 'ws://localhost:4000' }
  );
});

console.log('dev-server listening on 8015');
server.listen(8015);
