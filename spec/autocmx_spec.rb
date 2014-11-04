ENV['RACK_ENV'] = 'test'

require 'spec_helper'

describe 'The AutoCMX App' do
	it "displays the home page" do
		get '/'
		expect(last_response).to be_ok
	end

	it "displays homepage banner" do
		get '/'
		expect(last_response.body).to include("CMX Testing")
	end
end

describe 'Add tests' do
	it "adds good test" do
		post '/', {:name=>"Test User", :case=>"000000", :content=>"abc123"}
		expect(last_response.status).to eq 302
	end
	it "doesn't add only name" do
		post '/', {:name=>"Test User, only name"}
		expect(last_response).to_not be_ok
	end
	it "doesn't add only case" do
		post '/', {:case=>"012345"}
		expect(last_response).to_not be_ok
	end
	it "doesn't add only validator" do
		post '/', {:content=>"abceasyas123"}
		expect(last_response).to_not be_ok
	end		
end

describe 'Remove tests' do
	it "delete test" do
	end
end

describe "Data" do
	before :each do
		post '/', {:name=>"Validate Test", :case=>"validate", :content=>"doesitvalidate"}
	end
	it "validates correctly" do
		get '/data/1'
		expect(last_response.body).to include("doesitvalidate")
	end
end
