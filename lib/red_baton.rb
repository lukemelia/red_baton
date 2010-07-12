require 'uuid'

require 'deferrable_body'
require 'red_baton/channel_manager'
require 'red_baton/publish_endpoint'
require 'red_baton/subscribe_endpoint'
require 'red_baton/default_endpoint'

class RedBaton
  AsyncResponse = [-1, {}, []].freeze
  ASYNC_CALLBACK = "async.callback".freeze
  SESSION_ID_ENV_KEY = 'red_baton.session_id'.freeze

  attr_accessor :concurrency

  def initialize(opts = {})
    @concurrency = opts[:concurrency] || :broadcast
    @channel_manager = ChannelManager.new(@concurrency)
    @publish_endpoint = PublishEndpoint.new(@channel_manager)
    @subscribe_endpoint = SubscribeEndpoint.new(@channel_manager)
    @default_endpoint = DefaultEndpoint.new(@channel_manager)
  end

  def call(env)
    env[SESSION_ID_ENV_KEY] = UUID.generate
    url = env["PATH_INFO"]

    if url =~ %r{/publish/(.*)}
      channel_id = $1
      @publish_endpoint.handle(channel_id, env)
    elsif url =~ %r{/subscribe/(.*)}
      channel_id = $1
      @subscribe_endpoint.handle(channel_id, env)
    else
      @default_endpoint.handle(channel_id, env)
    end
  end
end