class RedBaton
  module ContentType
    TEXT_PLAIN = 'text/plain'.freeze
  end

  module Headers
    CONTENT_TYPE = 'Content-Type'.freeze
    ETAG = 'ETag'.freeze
    LAST_MODIFIED = 'Last-Modified'.freeze
    CHANNEL_SUBSCRIBERS = 'X-Channel-Subscribers'.freeze
    CHANNEL_MESSAGES = 'X-Channel-Messages'.freeze
    DEFAULT = { CONTENT_TYPE => ContentType::TEXT_PLAIN }
  end
  
  module Env
    PATH_INFO = 'PATH_INFO'.freeze
    IF_MODIFIED_SINCE = 'HTTP_IF_MODIFIED_SINCE'.freeze
    IF_NONE_MATCH = 'HTTP_IF_NONE_MATCH'.freeze
  end
end