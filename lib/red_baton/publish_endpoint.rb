require 'red_baton/endpoint'

class RedBaton
  class PublishEndpoint < Endpoint

    def handle(channel_id, env)
      case request_method(env)
      when 'POST'
        rack_request = Rack::Request.new(env)

        @channel_manager.publish(channel_id, rack_request.body.readlines.join("\n"))

        EventMachine.next_tick do
          async_response env, 201, {"Content-Type" => "text/plain"}, "Message delivered"
        end
      when 'GET'
        if @channel_manager.exists?(channel_id)
          EventMachine.next_tick do
            async_response env, 200, channel_info_headers(channel_id), "Channel exists"
          end
        else
          EventMachine.next_tick do
            async_response env, 404, {"Content-Type" => "text/plain"}, "Channel does not exist"
          end
        end
      when 'PUT'
        if @channel_manager.create(channel_id)
          EventMachine.next_tick do
            async_response env, 200, channel_info_headers(channel_id), "Channel created"
          end
        else
          EventMachine.next_tick do
            async_response env, 200, channel_info_headers(channel_id), "Channel exists"
          end
        end
      when 'DELETE'
        if @channel_manager.delete(channel_id)
          EventMachine.next_tick do
            async_response env, 200, channel_info_headers(channel_id), "Channel deleted"
          end
        else
          EventMachine.next_tick do
            async_response env, 404, {"Content-Type" => "text/plain"}, "Channel does not exist"
          end
        end
      else
        return invalid!("Unhandled HTTP method #{request_method(env)}")
      end

      RedBaton::AsyncResponse
    end

    def channel_info_headers(channel_id, extra_headers = { "Content-Type" => "text/plain" } )
      {
        "X-Channel-Subscribers" => @channel_manager.subscriber_count(channel_id).to_s,
        "X-Channel-Messages" => @channel_manager.message_count(channel_id).to_s
      }.merge(extra_headers)
    end
  end
end