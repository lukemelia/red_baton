class RedBaton
  class Endpoint
    include Thin::Logging

    REQUEST_METHOD = 'REQUEST_METHOD'.freeze
    HTTP_GET = 'GET'.freeze

    def initialize(channel_manager)
      @channel_manager = channel_manager
    end

    # def handle(channel_id, env)
    #   raise "Must be implemented by subclass"
    # end

    def request_method(env)
      env[REQUEST_METHOD]
    end

    def session_id(env)
      env[RedBaton::SESSION_ID_ENV_KEY]
    end

    def invalid!(msg='Invalid URL')
      [400, {"Content-Type" => "text/html"}, [msg]]
    end

    def async_response(env, status_code, headers, body)
      deferrable_body = DeferrableBody.new
      env[RedBaton::ASYNC_CALLBACK].call [status_code, headers, deferrable_body]
      deferrable_body.call([body])
      deferrable_body.succeed
    end
  end
end