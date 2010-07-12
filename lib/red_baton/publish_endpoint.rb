require 'red_baton/endpoint'

class RedBaton
  class PublishEndpoint < Endpoint

    def handle(channel_id, env)
      case request_method(env)
      when 'POST'
        rack_request = Rack::Request.new(env)

        @channel_manager.publish(channel_id, rack_request.body.readlines.join("\n"))

        async_201(env, channel_id, "Message delivered")
      when 'GET'
        if @channel_manager.exists?(channel_id)
          async_200(env, channel_id, "Channel exists")
        else
          async_404_channel_does_not_exist(env)
        end
      when 'PUT'
        if @channel_manager.create(channel_id)
          async_200(env, channel_id, "Channel created")
        else
          async_200(env, channel_id, "Channel exists")
        end
      when 'DELETE'
        if @channel_manager.delete(channel_id)
          async_200(env, channel_id, "Channel deleted")
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
        async_response(env, 404, {"Content-Type" => "text/plain"}, "Channel does not exist")
      end
    end

    def async_200(env, channel_id, message)
      EM.next_tick do
        async_response(env, 200, channel_info_headers(channel_id), message)
      end
    end

    def async_201(env, channel_id, message)
      EM.next_tick do
        async_response(env, 201, channel_info_headers(channel_id), message)
      end
    end

    def channel_info_headers(channel_id, extra_headers = { "Content-Type" => "text/plain" } )
      {
        "X-Channel-Subscribers" => @channel_manager.subscriber_count(channel_id).to_s,
        "X-Channel-Messages" => @channel_manager.message_count(channel_id).to_s
      }.merge(extra_headers)
    end
  end
end