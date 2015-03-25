Pusher.app_id = Setting.get(:pusher, :app_id)
Pusher.key = Setting.get(:pusher, :app_key)
Pusher.secret = Setting.get(:pusher, :secret)
Pusher.scheme = Setting.get(:pusher, :api_scheme)
Pusher.host = Setting.get(:pusher, :api_host)
Pusher.port = Setting.get(:pusher, :api_port).to_i
