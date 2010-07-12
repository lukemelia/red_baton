class RedBaton
  class DefaultEndpoint < Endpoint
    def handle(channel_id, env)
      not_found!
    end
    
  private
    def not_found!
      [404, {"Content-Type" => "text/html"}, ["404 Not Found"]]
    end
  end
end