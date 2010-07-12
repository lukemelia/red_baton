require 'red_baton/endpoint'

class RedBaton
  class SubscribeEndpoint < Endpoint

    def handle(channel_id, env)
      unless request_method(env) == HTTP_GET
        return immediate_405_get_requests_only
      end
        
      EM.next_tick do
        if register_subscriber(channel_id, session_id(env))
          subscriber_poll(channel_id, env)
        else
          async_409_prior_connection(env)
        end
      end
      RedBaton::AsyncResponse
    end
    
  private
  
    def register_subscriber(channel_id, session_id)
      @channel_manager.register_active_subscriber(channel_id, session_id)
    end
  
    def async_409_prior_connection(env)
      async_response env, 409, {"Content-Type" => "text/plain"}, "Already a connection on this channel"
    end

    def async_409_newer_connection(env)
      async_response env, 409, {"Content-Type" => "text/plain"}, "Newer connection on this channel"
    end
    
    def async_410_channel_gone(env)
      async_response env, 410, {"Content-Type" => "text/plain"}, "Gone. Channel no longer exists"
    end
    
    def async_200_with_message(env, message)
      async_response env, 200, {"Content-Type" => "text/plain"}, message
    end
    
    def immediate_405_get_requests_only
      [405, {"Content-Type" => "text/plain"}, "Only GET requests are allowed."]
    end
    
    def perform_subscriber_disconnect(session_id, channel_id, env)
      debug "perform_subscriber_disconnect #{session_id.inspect}, #{channel_id.inspect}"
      @channel_manager.unregister_subscriber(channel_id, session_id)
      if @channel_manager.exists?(channel_id)
        async_409_newer_connection(env)
      else
        async_410_channel_gone(env)
      end
    end

    def subscriber_poll(channel_id, env)
      my_session_id = session_id(env)
      if @channel_manager.should_disconnect?(my_session_id)
        perform_subscriber_disconnect(my_session_id, channel_id, env)
        
      elsif message = @channel_manager.pop_subscriber_message(my_session_id)
        async_200_with_message(env, message)

      elsif message = @channel_manager.pop_channel_message(channel_id)
        async_200_with_message(env, message)

      else
        EM.next_tick do
          subscriber_poll(channel_id, env)
        end
      end
    end

  end
end