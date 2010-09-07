class RedBaton
  module Endpoint
    class Publish < Endpoint::ChannelGroup
      CHANNEL_CREATED = 'Channel created'.freeze
      CHANNEL_DELETED = 'Channel deleted'.freeze
      CHANNEL_EXISTS = 'Channel exists'.freeze
      CHANNEL_DOES_NOT_EXIST = 'Channel does not exist'.freeze
      MESSAGE_DELIVERED = 'Message delivered'.freeze
      MESSAGE_ACCEPTED = 'Message accepted'.freeze

      def handle(channel_id, env)
        case request_method(env)
        when HTTP_POST
          rack_request = Rack::Request.new(env)
          message = Message.new(rack_request.body.readlines.join("\n"), Time.now, rack_request.content_type)
          immediate_publish_count = @channel_manager.publish(channel_id, message)

          if immediate_publish_count > 0
            async_201(env, channel_id, MESSAGE_DELIVERED)
          else
            async_202(env, channel_id, MESSAGE_ACCEPTED)
          end
        when HTTP_GET
          if @channel_manager.exists?(channel_id)
            async_200(env, channel_id, CHANNEL_EXISTS)
          else
            async_404_channel_does_not_exist(env)
          end
        when HTTP_PUT
          if @channel_manager.create(channel_id)
            async_200(env, channel_id, CHANNEL_CREATED)
          else
            async_200(env, channel_id, CHANNEL_EXISTS)
          end
        when HTTP_DELETE
          if @channel_manager.delete(channel_id)
            async_200(env, channel_id, CHANNEL_DELETED)
          else
            async_404_channel_does_not_exist(env)
          end
        else
          return invalid!("Unhandled HTTP method #{request_method(env)}")
        end

        RedBaton::AsyncResponse
      end

    private

      def async_404_channel_does_not_exist(env)
        EM.next_tick do
          async_response(env, 404, CHANNEL_DOES_NOT_EXIST)
        end
      end

      def async_200(env, channel_id, message)
        EM.next_tick do
          async_response(env, 200, message, channel_info_headers(channel_id))
        end
      end

      def async_201(env, channel_id, message)
        EM.next_tick do
          async_response(env, 201, message, channel_info_headers(channel_id))
        end
      end

      def async_202(env, channel_id, message)
        EM.next_tick do
          async_response(env, 202, message, channel_info_headers(channel_id))
        end
      end

      def channel_info_headers(channel_id, extra_headers = Headers::DEFAULT)
        {
          Headers::CHANNEL_SUBSCRIBERS => @channel_manager.subscriber_count(channel_id).to_s,
          Headers::CHANNEL_MESSAGES => @channel_manager.message_count(channel_id).to_s
        }.merge(extra_headers)
      end
    end
  end
end