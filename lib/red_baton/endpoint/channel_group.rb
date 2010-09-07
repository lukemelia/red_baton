class RedBaton
  module Endpoint
    class ChannelGroup < Base
      def initialize(channel_manager, path_specifier)
        @channel_manager = channel_manager
        @path_regex = %r{^#{Regexp.escape(path_specifier).gsub(/:channel_id/, '(.*)')}}.freeze
      end
    
      def handles?(path)
        if path =~ @path_regex
          $1
        else
          false
        end
      end
    end
  end
end
