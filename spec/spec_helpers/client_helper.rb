require 'net/http'
require 'uri'

def get(endpoint)
  url = URI.parse("http://0.0.0.0:3001#{endpoint}")
  Net::HTTP.start(url.host, url.port) {|http|
    http.read_timeout = 5
    http.get(endpoint)
  }
rescue EOFError => e # stopping Thin during open connection
  # OK
rescue Timeout::Error => e
  return nil
end

def post(endpoint, request_body)
  url = URI.parse("http://0.0.0.0:3001#{endpoint}")
  Net::HTTP.start(url.host, url.port) {|http|
    http.read_timeout = 5
    http.post(endpoint, request_body)
  }
rescue EOFError => e # stopping Thin during open connection
  # OK
rescue Timeout::Error => e
  return nil
end

def put(endpoint, request_body = '')
  url = URI.parse("http://0.0.0.0:3001#{endpoint}")
  Net::HTTP.start(url.host, url.port) {|http|
    http.read_timeout = 5
    http.put(endpoint, request_body)
  }
rescue EOFError => e # stopping Thin during open connection
  # OK
rescue Timeout::Error => e
  return nil
end

def delete(endpoint)
  url = URI.parse("http://0.0.0.0:3001#{endpoint}")
  Net::HTTP.start(url.host, url.port) {|http|
    http.read_timeout = 5
    http.delete(endpoint)
  }
rescue EOFError => e # stopping Thin during open connection
  # OK
rescue Timeout::Error => e
  return nil
end

def send_options_request(endpoint)
  url = URI.parse("http://0.0.0.0:3001#{endpoint}")
  Net::HTTP.start(url.host, url.port) {|http|
    http.read_timeout = 5
    http.options(endpoint)
  }
rescue EOFError => e # stopping Thin during open connection
  # OK
rescue Timeout::Error => e
  return nil
end
