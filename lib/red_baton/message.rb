class RedBaton
  class Message
    def initialize(body, timestamp, content_type)
      @body = body
      @timestamp = timestamp
      @content_type = content_type
    end
    
    attr_reader :body, :timestamp, :content_type
    
    def http_timestamp
      @timestamp.httpdate
    end
    
    def etag
      @etag ||= Digest::MD5.hexdigest("#{@body}#{@timestamp}#{@content_type}")
    end
    
    def increment_timestamp
      @timestamp += 1
    end
  end
end
