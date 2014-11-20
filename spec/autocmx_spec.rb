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

describe 'When Adding tests' do
	it "has a status code of 302 if test added successfully" do
		post '/', {:name=>"Test User", :case=>"000000", :secret=>"test_secret", :content=>"abc123"}
		expect(last_response.status).to eq 302
	end
	it "gives an error if test only has name" do
		post '/', {:name=>"Test User, only name"}
		expect(last_response).to_not be_ok
	end
	it "gives an error if test only has a case" do
		post '/', {:case=>"Test User, only case"}
		expect(last_response).to_not be_ok
	end
  it "gives an error if test only has a secret" do 
    post '/', {:secret=>"Test User, only secret"}
    expect(last_response).to_not be_ok
  end
	it "gives an error if the test only has a validator" do
		post '/', {:content=>"Test User, only validator"}
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
