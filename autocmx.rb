require "rubygems"
require "sinatra"
require "sequel"
require "rack-flash"
require "sinatra/redirect_with_flash"
require "json"
require "yaml"
require "rack-google-analytics"
require "logger"

enable :sessions

use Rack::Flash, :sweep => true
CONFIG = YAML.load_file("config.yml") unless defined? CONFIG

SITE_TITLE = "CMX Testing"
SITE_DESCRIPTION = "Automated CMX test server"
SECRET = CONFIG['secret']
HOSTNAME = CONFIG['hostname']
PORT = CONFIG['port']

# Create a log file instead of just printing to output
log = Logger.new(CONFIG['log_file'],5, 1024000)

log.debug "This is a test"
set :session_secret, CONFIG['session_secret']

use Rack::GoogleAnalytics, :tracker => CONFIG['tracker']

puts "Setting up server at #{HOSTNAME}:#{PORT} with the SECRET #{SECRET}"
log.info("Server is set up at #{HOSTNAME}:#{PORT} with the SECRET=#{SECRET}")

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
	String :state, :text => true
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
		n.data_at = Time.now
		if request.media_type == "application/json"
			request.body.rewind
			map = JSON.parse(request.body.read)
		else
			map = JSON.parse(params['data'])
		end
		if map == nil
			request.body.rewind
			logger.warn "#{params[:id]} Could not parse POST body #{request.body.read}"
			log.warn("#{params[:id]} *** Could not parse POST body #{request.body.read}")
			n.state = "bad_post"
			n.save
			return
		end
		if map['secret'] != n.secret
			logger.warn "#{params[:id]} Got post with bad secret: #{map['secret']}"
			log.warn("#{params[:id]} *** bad secret #{map['secret']}")
			n.state = "bad_secret"
			n.save
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
			log.warn("#{params[:id]} *** Test #{params[:id]} -- Unknown API version: #{map['version']}")
			n.api = map['version']
			n.state = "bad_api"
			n.save
			return
		end
		logger.info "#{params[:id]} Post data are (First 100 characters): #{data[0, 99]}#"
		log.info("#{params[:id]} Post data -- (First 100 characters): #{data[0, 99]}#")
		n.state = "complete"
		n.complete = true
		n.save
	else
		logger.info "Received data for test #{params[:id]}, but don't have that configured"
		log.error("***** Data recieved for unconfigured test #{params[:id]}")
	end
end

# Home Page
get "/" do 
	@tests = DB[:tests]
	@title = "All Tests"
	if @tests.empty?
		flash[:notice] = "No pending tests found. Add your first below."
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
	n.complete = false
	n.push_url = "http://#{HOSTNAME}:#{PORT}/data/"
	n.state = "no_data_received"
  if n.valid?
    n.save
    flash[:notice] = "Test created successfully." 
		redirect "/"
	else
		flash[:error] = "Unable to save test, please make sure you fill out all fields"
    redirect "/"
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
post "/:id/edit" do
	n = Test.first(:id => params[:id])
	unless n
		redirect "/", :error => "Can't find that test."
	end
	n.name = params[:name]
	n.case = params[:case]
	n.secret = params[:secret]
	n.validator = params[:validator]
	n.complete = params[:complete] ? 1 : 0
	n.state = "no_data_received"
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
		log.info("Test #{:id} was deleted")
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
	n.state = "complete"
	n.complete = n.complete ? 0 : 1 #flip it
	n.updated_at = Time.now
	if n.save
		redirect "/", :notice => "Test marked as complete."
	else
		redirect "/", :error => "Error marking test as complete."
	end
end


