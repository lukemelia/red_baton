require 'uuid'

require 'deferrable_body'
require 'red_baton/constants'
require 'red_baton/message'
require 'red_baton/channel_manager'
require 'red_baton/endpoint'

class RedBaton
  AsyncResponse = [-1, {}, []].freeze
  ASYNC_CALLBACK = "async.callback".freeze
  SESSION_ID_ENV_KEY = 'red_baton.session_id'.freeze

  def initialize(config_collection = nil)
    config_collection = [{}] if config_collection.nil?
    config_collection = [config_collection] unless config_collection.is_a?(Array)
    
    @channel_managers = {}
    @publish_endpoints = []
    @subscribe_endpoints = []
    
    config_collection.each do |opts|
      concurrency = opts[:concurrency] || :broadcast
      store_messages = opts[:store_messages] || false
      max_messages = opts[:max_messages] || 5
      subscribe_path = opts[:subscribe_path] || '/subscribe/:channel_id'
      publish_path = opts[:publish_path] || '/publish/:channel_id'
      channel_group = opts[:channel_group] || :default
      @channel_managers[channel_group] ||= ChannelManager.new(concurrency, store_messages, max_messages)
      @publish_endpoints << Endpoint::Publish.new(@channel_managers[channel_group], publish_path)
      @subscribe_endpoints << Endpoint::Subscribe.new(@channel_managers[channel_group], subscribe_path)
    end
    @default_endpoint = Endpoint::Default.new
  end
  
  def concurrency(channel_group = :default)
    @channel_managers[channel_group].concurrency
  end

  def call(env)
    env[SESSION_ID_ENV_KEY] = UUID.generate
    url = env[Env::PATH_INFO]
    
    @publish_endpoints.each do |publish_endpoint|
      if channel_id = publish_endpoint.handles?(url)
        return publish_endpoint.handle(channel_id, env)
      end
    end
    
    @subscribe_endpoints.each do |subscribe_endpoint|
      if channel_id = subscribe_endpoint.handles?(url)
        return subscribe_endpoint.handle(channel_id, env)
      end
    end

    return @default_endpoint.handle(nil, env)
  end
end
