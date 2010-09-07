require 'net/http'
require 'uri'

def get(endpoint, special_headers = {})
  url = URI.parse("http://0.0.0.0:3001#{endpoint}")
  Net::HTTP.start(url.host, url.port) {|http|
    http.read_timeout = 5
    http.get(endpoint, special_headers)
  }
rescue EOFError => e # stopping Thin during open connection
  # OK
rescue Timeout::Error => e
  return nil
end

def post(endpoint, request_body, special_headers = {})
  url = URI.parse("http://0.0.0.0:3001#{endpoint}")
  Net::HTTP.start(url.host, url.port) {|http|
    http.read_timeout = 5
    http.post(endpoint, request_body, special_headers)
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

class SubscribeResult
  attr_accessor :response
  attr_accessor :thread
  def thread_join
    thread.join
  end
  def body
    response.body
  end
  def code
    response.code.to_i
  end
end

def subscribe(endpoint, opts = {})
  publish_endpoint = endpoint.gsub(/subscribe/, 'publish').gsub(/sub/, 'pub')
  starting_number_of_subscribers = get(publish_endpoint).response.header['x-channel-subscribers'].to_i
  
  request_headers = {}
  request_headers['If-Modified-Since'] = opts[:if_modified_since] if opts[:if_modified_since]
  request_headers['If-None-Match'] = opts[:if_none_match] if opts[:if_none_match]
  subscribe_result = SubscribeResult.new
  subscribe_result.thread = Thread.new do
    subscribe_result.response = get(endpoint, request_headers)
  end

  poll_until {
    get(publish_endpoint).response.header['x-channel-subscribers'].to_i == starting_number_of_subscribers + 1
  }
  subscribe_result
end