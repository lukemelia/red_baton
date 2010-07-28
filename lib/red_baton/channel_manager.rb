class RedBaton
  class ChannelManager
    include Thin::Logging
    
    attr_reader :concurrency

    def initialize(concurrency, store_messages = false, max_messages = 5)
      @concurrency = concurrency
      @store_messages = store_messages
      @max_messages = max_messages
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

    def publish(channel_id, message)
      debug "publish(#{channel_id.inspect}, #{message.inspect})"
      
      if @store_messages
        add_to_channel_message_queue(channel_id, message)
      end
      
      immediate_publish_count = 0
      (@channel_subscribers[channel_id] || []).each do |session_id|
        subscriber_message_queue = @subscriber_messages[session_id] ||= []
        subscriber_message_queue.unshift(message)
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

    def get_channel_message(channel_id, if_modified_since, if_none_match)
      debug "pop_channel_message(#{channel_id.inspect})"
      message_queue = @channel_messages[channel_id] || []
      message_queue.detect do |message|
        if if_none_match.nil? && if_modified_since.nil?
          true
        else
          if if_none_match && (message.etag == if_none_match)
            false
          elsif if_modified_since && (message.timestamp.to_i <= Time.parse(if_modified_since).to_i)
            false
          else
            true
          end
        end
      end
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
    
    def add_to_channel_message_queue(channel_id, message)
      channel_message_queue = @channel_messages[channel_id] ||= []
      if channel_message_queue.any? && channel_message_queue.last.timestamp.to_i == message.timestamp.to_i
        message.increment_timestamp
      end
      channel_message_queue.push(message)
      if channel_message_queue.size > @max_messages
        channel_message_queue.shift
      end
    end
  end
end