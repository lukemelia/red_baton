ENV["RAILS_ENV"] = "test"

require "rubygems"
require "bundler"
Bundler.setup

require 'spec'
require 'thin'
require 'red_baton'
require 'typhoeus'

Thread.abort_on_exception = true

Pathname.glob(Pathname.new(File.dirname(__FILE__)).join("spec_helpers/*.rb")).each do |filename|
  require filename.to_s
end

Spec::Runner.configure do |config|

end