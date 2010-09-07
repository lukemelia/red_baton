class RedBaton
  module Endpoint
    class Default < Endpoint::Base
    
      NOT_FOUND = '404 Not Found'.freeze
    
      def handle(channel_id, env)
        not_found!
      end
    
    private
    
      def not_found!
        [404, Headers::DEFAULT, [NOT_FOUND]]
      end
    
    end
  end
end