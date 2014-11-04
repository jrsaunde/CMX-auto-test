require_relative '../autocmx'

require 'sinatra'
require 'sinatra/base'
require 'rack/test'

def app
  Sinatra::Application
end

RSpec.configure do |config|
  config.tty = true
  config.formatter = :documentation
  config.include Rack::Test::Methods
end
