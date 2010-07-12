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
        debug "Handling GET for #{channel_id.inspect}"
        if @channel_manager.exists?(channel_id)
          EventMachine.next_tick do
            async_response env, 200, {"Content-Type" => "text/plain", "X-Subscribers" => @channel_manager.subscriber_count(channel_id).to_s}, "Channel exists"
          end
        else
          EventMachine.next_tick do
            async_response env, 404, {"Content-Type" => "text/plain"}, "Channel does not exist"
          end
        end
      when 'PUT'
        if @channel_manager.create(channel_id)
          EventMachine.next_tick do
            async_response env, 200, {"Content-Type" => "text/plain"}, "Channel created"
          end
        else
          EventMachine.next_tick do
            async_response env, 200, {"Content-Type" => "text/plain"}, "Channel exists"
          end
        end
      when 'DELETE'
        if @channel_manager.delete(channel_id)
          EventMachine.next_tick do
            async_response env, 200, {"Content-Type" => "text/plain"}, "Channel deleted"
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
    
  end
end