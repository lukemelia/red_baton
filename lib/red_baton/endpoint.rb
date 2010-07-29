class RedBaton
  class Endpoint
    include Thin::Logging

    REQUEST_METHOD = 'REQUEST_METHOD'.freeze
    
    HTTP_GET = 'GET'.freeze
    HTTP_POST = 'POST'.freeze
    HTTP_PUT = 'PUT'.freeze
    HTTP_DELETE = 'DELETE'.freeze
    
    INVALID_URL_MSG = 'Invalid URL'.freeze

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

    def invalid!(msg = INVALID_URL_MSG)
      [400, Headers::DEFAULT, [msg]]
    end

    def async_response(env, status_code, body, headers = Headers::DEFAULT)
      deferrable_body = DeferrableBody.new
      env[RedBaton::ASYNC_CALLBACK].call [status_code, headers, deferrable_body]
      deferrable_body.call([body])
      deferrable_body.succeed
    end
  end
end