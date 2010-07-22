class RedBaton
  class ChannelManager
    include Thin::Logging
    
    attr_reader :concurrency

    def initialize(concurrency, store_messages = false)
      @concurrency = concurrency
      @store_messages = store_messages
      @channel_subscribers = {}
      @channel_messages = {}
      @subscriber_messages = {}
      @session_disconnects = Set.new
    end

    def register_active_subscriber(channel_id, session_id)
      debug "register_active_subscriber(#{channel_id.inspect}, #{session_id.inspect})"

      ensure_created(channel_id)
      subscribers = @channel_subscribers[channel_id]

      if subscribers.length > 0
        case @concurrency
        when :last
          subscribers.each do |older_session_id|
            initiate_disconnect(older_session_id)
          end
        when :first
          return false
        end
      end

      subscribers.add(session_id)

      true
    end

    def unregister_subscriber(channel_id, session_id)
      if subscribers = @channel_subscribers[channel_id]
        subscribers.delete?(session_id)
      end
    end

    def publish(channel_id, message, content_type)
      debug "publish(#{channel_id.inspect}, #{message.inspect}, #{content_type.inspect})"
      message_with_content_type = "#{content_type}\n\n#{message}".freeze
      
      if @store_messages
        channel_message_queue = @channel_messages[channel_id] ||= []
        channel_message_queue.unshift(message_with_content_type)
      end
      
      immediate_publish_count = 0
      (@channel_subscribers[channel_id] || []).each do |session_id|
        subscriber_message_queue = @subscriber_messages[session_id] ||= []
        subscriber_message_queue.unshift(message_with_content_type)
        immediate_publish_count += 1
      end
      immediate_publish_count
    end

    def exists?(channel_id)
      debug "exists?(#{channel_id.inspect}): #{@channel_subscribers.key?(channel_id).inspect}"
      @channel_subscribers.key?(channel_id)
    end
    
    def subscriber_count(channel_id)
      return 0 unless exists?(channel_id)
      @channel_subscribers[channel_id].size
    end
    
    def message_count(channel_id)
      return 0 unless exists?(channel_id)
      (@channel_messages[channel_id] || []).size
    end

    def create(channel_id)
      debug "create(#{channel_id.inspect})"
      if exists?(channel_id)
        false
      else
        @channel_subscribers[channel_id] ||= Set.new
        true
      end
    end

    alias :ensure_created :create

    def delete(channel_id)
      debug "delete(#{channel_id.inspect})"
      return false unless exists?(channel_id)
      initiate_channel_subscribers_disconnect(channel_id)
      @channel_subscribers.delete(channel_id)
      @channel_messages.delete(channel_id)
      true
    end
    
    def initiate_channel_subscribers_disconnect(channel_id)
      debug "initiate_channel_subscribers_disconnect(#{channel_id.inspect})"
      return unless exists?(channel_id)
      @channel_subscribers[channel_id].each do |session_id|
        initiate_disconnect(session_id)
      end
    end

    def get_channel_message(channel_id)
      debug "pop_channel_message(#{channel_id.inspect})"
      message_queue = @channel_messages[channel_id] || []
      message_queue.first
    end

    def pop_subscriber_message(session_id)
      debug "pop_subscriber_message(#{session_id.inspect})"
      message_queue = @subscriber_messages[session_id] || []
      message_queue.pop
    end

    def initiate_disconnect(session_id)
      debug "initiate_disconnect(#{session_id.inspect})"
      debug "Adding #{session_id} to #{@session_disconnects.inspect}"
      @session_disconnects.add(session_id)
    end

    def should_disconnect?(session_id)
      debug "should_disconnect?(#{session_id.inspect})"
      @session_disconnects.delete?(session_id)
    end
  end
end