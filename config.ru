# This file is used by Rack-based servers to start the application.

# require ::File.expand_path('../config/environment',  __FILE__)
# run RedBaton::Application

app = proc do |env|
  [
    200,          # Status code
    {             # Response headers
      'Content-Type' => 'text/html',
      'Content-Length' => '2',
    },
    ['hi']        # Response body
  ]
end

# You can install Rack middlewares
# to do some crazy stuff like logging,
# filtering, auth or build your own.
# use Rack::CommonLogger

run app