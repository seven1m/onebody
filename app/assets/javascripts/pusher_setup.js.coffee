#= require pusher

if pusher_config?
  Pusher.dependency_suffix = '.min'

  Pusher.Dependencies = new Pusher.DependencyLoader
    cdn_http: '/pusher-js/'
    cdn_https: '/pusher-js/'
    version: Pusher.VERSION
    suffix: Pusher.dependency_suffix

  if window.DEBUG
    Pusher.log = (message) ->
      console.log(message)

  window.pusher = new Pusher pusher_config.app,
    wsHost: pusher_config.wsHost
    wsPort: pusher_config.wsPort
    wssPort: pusher_config.wssPort
    enabledTransports: ['ws', 'flash']
    authEndpoint: '/pusher/auth_printer'
