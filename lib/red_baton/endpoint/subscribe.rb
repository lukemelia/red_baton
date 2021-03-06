class RedBaton
  module Endpoint
    class Subscribe < Endpoint::ChannelGroup
      PRIOR_CONNECTION = 'Already a connection on this channel'.freeze
      NEWER_MESSAGE = 'Newer connection on this channel'.freeze
      CHANNEL_GONE = 'Gone. Channel no longer exists'.freeze
      GET_REQUESTS_ONLY = 'Only GET requests are allowed'.freeze
        
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
        async_response(env, 409, PRIOR_CONNECTION)
      end

      def async_409_newer_connection(env)
        async_response(env, 409, NEWER_MESSAGE)
      end
    
      def async_410_channel_gone(env)
        async_response(env, 410, CHANNEL_GONE)
      end
    
      def async_200_with_message(env, message)
        async_response env, 200, message.body,
                       { Headers::LAST_MODIFIED => message.http_timestamp,
                         Headers::ETAG => message.etag,
                         Headers::CONTENT_TYPE => message.content_type }
      end
    
      def immediate_405_get_requests_only
        [405, Headers::DEFAULT, GET_REQUESTS_ONLY]
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

        elsif message = @channel_manager.get_channel_message(channel_id, env[Env::IF_MODIFIED_SINCE], env[Env::IF_NONE_MATCH])
          async_200_with_message(env, message)

        else
          EM.next_tick do
            subscriber_poll(channel_id, env)
          end
        end
      end

    end
  end
end