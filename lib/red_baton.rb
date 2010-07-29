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

  def initialize(opts = {})
    concurrency = opts[:concurrency] || :broadcast
    store_messages = opts[:store_messages] || false
    max_messages = opts[:max_messages] || 5
    subscribe_path = opts[:subscribe_path] || '/subscribe/:channel_id'
    publish_path = opts[:publish_path] || '/publish/:channel_id'
    @channel_manager = ChannelManager.new(concurrency, store_messages, max_messages)
    @publish_endpoint = Endpoint::Publish.new(@channel_manager, publish_path)
    @subscribe_endpoint = Endpoint::Subscribe.new(@channel_manager, subscribe_path)
    @default_endpoint = Endpoint::Default.new
  end
  
  def concurrency
    @channel_manager.concurrency
  end

  def call(env)
    env[SESSION_ID_ENV_KEY] = UUID.generate
    url = env[Env::PATH_INFO]

    if channel_id = @publish_endpoint.handles?(url)
      @publish_endpoint.handle(channel_id, env)
    elsif channel_id = @subscribe_endpoint.handles?(url)
      @subscribe_endpoint.handle(channel_id, env)
    else
      @default_endpoint.handle(channel_id, env)
    end
  end
end
