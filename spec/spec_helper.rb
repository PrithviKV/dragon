require 'rack/test'
require 'rspec'

ENV['RACK_ENV'] = 'test'

require File.expand_path '../../my_api.rb', __FILE__

module RSpecMixin
  include Rack::Test::Methods
  def app() MyApi end
end

RSpec.configure { |c| c.include RSpecMixin }

