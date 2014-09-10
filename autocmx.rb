require "rubygems"
require "sinatra"
require "data_mapper"
require "rack-flash"
require "sinatra/redirect_with_flash"
require "json"
require "yaml"
require "rack-google-analytics"

enable :sessions

use Rack::Flash, :sweep => true
CONFIG = YAML.load_file("config.yml") unless defined? CONFIG

SITE_TITLE = "CMX Testing"
SITE_DESCRIPTION = "Automated CMX test server"
SECRET = CONFIG['secret']
HOSTNAME = CONFIG['hostname']
PORT = CONFIG['port']

set :session_secret, CONFIG['session_secret']

use Rack::GoogleAnalytics, :tracker => CONFIG['tracker']

puts "Setting up server at #{HOSTNAME}:#{PORT} with the SECRET #{SECRET}"

if (CONFIG['db_driver'])
	DataMapper::setup(:default, CONFIG['db_driver'])
else
	DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/cmxtests.db")
end

class Test
	include DataMapper::Resource
	property :id, Serial
	property :name, Text, :required=> true
	property :case, Text, :required=> true
	property :secret, Text
	property :api, Integer
	property :push_url, Text
	property :validator, Text, :required=> true
	property :complete, Boolean, :required => true, :default => false
	property :created_at, DateTime
	property :updated_at, DateTime
	property :data_at, DateTime
end

DataMapper.finalize.auto_upgrade!

helpers do
	include Rack::Utils
	alias_method :h, :escape_html
end

# RSS Feeds 
get "/rss.xml" do
	@tests = Test.all :order => :id.desc
	builder :rss
end

# List all Tests
get "/list" do
        @tests = Test.all :order => :id.desc
        @title = "All Tests"
        if @tests.empty?
                flash[:error] = "No pending tests found."
        end
        erb :list
end

#Test
get "/data/:id" do
        @test = Test.get params[:id]
        if @test
                @test.validator
        else
                redirect "/", :error => "Can't find that test."
        end
end

#Recieve data
post "/data/:id" do
  n = Test.get params[:id]
  if n
	  if request.media_type == "application/json"
    		request.body.rewind
    		map = JSON.parse(request.body.read)
  	  else
    		map = JSON.parse(params['data'])
  	  end
  	  if map == nil
    	  	request.body.rewind
    		logger.warn "Could not parse POST body #{request.body.read}"
    	  	return
  	  end
  	  if map['secret'] != SECRET
    		logger.warn "#{params[:id]} Got post with bad secret: #{map['secret']}"
    		return
  	  end
  	  logger.info "Version is #{map['version']}"
  	  #@test = Test.get params[:id]
  	  if map['version'] == '1.0'
		n.api = 1
    		data = map['probing'].to_s
  	  else
		n.api = 2
    		data = map['data'].to_s
  	  end
  	  logger.info "Post data are (First 1000 characters): #{data[0, 999]}#"
	  n.data_at = Time.now
	  n.complete = true
	  n.save
  else
          logger.info "Received data for test #{params[:id]} but don't have that configured"
  end
end

# Home Page
get "/" do 
	@tests = Test.all :order => :id.desc
	@title = "All Tests"
	if @tests.empty?
		flash[:error] = "No pending tests found. Add your first below."
	end
	erb :home
end

# Post a test
post "/" do
	n = Test.new
	n.secret = "Meraki123"
	n.validator = params[:content]
	n.name = params[:name]
	n.case = params[:case]
	n.push_url = "http://#{HOSTNAME}:#{PORT}/data/"
	n.created_at = Time.now
	n.updated_at = Time.now
	if n.save
		redirect "/", :notice => 'Test created successfully.'
	else
		redirect "/", :error => 'Failed to save test.'
	end
end

# Edit a test -- get
get "/:id" do 
	@test = Test.get params[:id]
	@title = "Edit test ##{params[:id]}"
	if @test
		erb :edit
	else 
		redirect "/", :error => "Can't find that test."
	end
end

# Edit a test -- post
put "/:id" do
	n = Test.get params[:id]
	unless n
		redirect "/", :error => "Can't find that test."
	end
	n.validator = params[:validator]
	n.complete = params[:complete] ? 1 : 0
	n.updated_at = Time.now
	if n.save
		redirect "/", :notice => "Test updated successfully."
	else
		redirect "/", :error => "Error updating test."
	end
end

# Delete a test -- get
get "/:id/delete" do
	@test = Test.get params[:id]
	@title = "Confirm deletion of test ##{params[:id]}"
	if @test
		erb :delete
	else
		redirect "/", :error => "Can't find that test."
	end
end

# Delete a test -- delete
delete "/:id" do 
	n = Test.get params[:id]
	if n.destroy
		redirect "/", :notice => "Test deleted successfully."
	else
		redirect "/", :error => "Error deleting Test."
	end
end

# Mark a Test complete -- get
get "/:id/complete" do
	n = Test.get params[:id]
	unless n
		redirect "/", :error => "Can't find that test."
	end
	n.complete = n.complete ? 0 : 1 #flip it
	n.updated_at = Time.now
	if n.save
		redirect "/", :notice => "Test marked as complete."
	else
		redirect "/", :error => "Error marking test as complete."
	end
end


