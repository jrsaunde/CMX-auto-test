require "rubygems"
require "sinatra"
require "sequel"
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

if (PORT)
	set :port, PORT
end
if (CONFIG['bind'])
	set :bind, CONFIG['bind']
end
if (CONFIG['db_driver'])
	DB = Sequel.connect(CONFIG['db_driver'])
else
	DB = Sequel.connect("sqlite://#{Dir.pwd}/cmxtests.db")
end

DB.create_table? :tests do
	primary_key :id
	String :name, :text => true, :null => false
	String :case, :null => false
	String :secret
	Float :api
	String :push_url
	String :validator, :null => false
	Boolean :complete, :default => false
	DateTime :created_at
	DateTime :updated_at
	DateTime :data_at
end

Sequel::Model.plugin :validation_helpers

class Test < Sequel::Model
	def validate
		super
		validates_presence [:name, :case, :validator, :complete, :secret]
		validates_max_length 30, :name
		validates_max_length 20, :case
	end

	def before_create
		self.created_at = Time.now
		super
	end

	def before_save
		self.updated_at = Time.now
		super
	end
end

helpers do
	include Rack::Utils
	alias_method :h, :escape_html
end

# List all Tests
get "/list" do
	@tests = DB[:tests]
	@title = "All Tests"
	if @tests.empty?
		flash[:error] = "No tests found."
	end
	erb :list
end

#Test
get "/data/:id" do
	@test = Test.first(:id => params[:id])
	if @test
		@test.validator
	else
		redirect "/", :error => "Can't find that test."
	end
end

#Recieve data
post "/data/:id" do
	n = Test.first(:id => params[:id])
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

		if map['version'] == '1.0'
			n.api = 1.0
			data = map['probing'].to_s
		elsif map['version'] == '2.0'
			n.api = 2.0
			data = map['data'].to_s
		else
			logger.warn "#{params[:id]} Got post with unknown API version: #{map['version']}"
			return
		end
		logger.info "Post data are (First 100 characters): #{data[0, 99]}#"
		n.data_at = Time.now
		n.complete = true
		n.save
	else
		logger.info "Received data for test #{params[:id]}, but don't have that configured"
	end
end

# Home Page
get "/" do 
	@tests = DB[:tests]
	@title = "All Tests"
	if @tests.empty?
		flash[:error] = "No pending tests found. Add your first below."
	end
	erb :home
end

# Post a test
post "/" do
	n = Test.new
	n.secret = params[:secret] ? params[:secret] : SECRET
	n.validator = params[:content]
	n.name = params[:name]
	n.case = params[:case]
	n.push_url = "http://#{HOSTNAME}:#{PORT}/data/"
	if n.save
		redirect "/", :notice => 'Test created successfully.'
	else
		redirect "/", :error => 'Failed to save test.'
	end
end

# Edit a test -- get
get "/:id/edit" do 
	@test = Test.first(:id => params[:id])
	@title = "Edit test ##{params[:id]}"
	if @test
		erb :edit
	else 
		redirect "/", :error => "Can't find that test."
	end
end

# Edit a test -- post
put "/:id/edit" do
	n = Test.first(:id => params[:id])
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
	@test = Test.first(:id => params[:id])
	@title = "Confirm deletion of test ##{params[:id]}"
	if @test
		erb :delete
	else
		redirect "/", :error => "Can't find that test."
	end
end

# Delete a test -- delete
delete "/:id" do 
	n = Test.first(:id => params[:id])
	if n.destroy
		redirect "/", :notice => "Test deleted successfully."
	else
		redirect "/", :error => "Error deleting Test."
	end
end

# Mark a Test complete -- get
get "/:id/complete" do
	n = Test.first(:id => params[:id])
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


