
require File.expand_path '../spec_helper.rb', __FILE__

describe "My Api" do
	before(:all) do 
	  $time_created = Time.now.to_i
	  $time_updated = Time.now.to_i
	end

	let(:t) {Time.now.to_i}
 
	it "should store key and value" do
		body = { :key => "xyz"}.to_json 
    post '/api/v1/object?access_token=access_token', body, {'Content-Type' => 'application/json'}
    $time_created = Time.now.to_i
    expect(last_response).to be_ok
  end

  it "should accept a key and return a value" do
    get '/api/v1/object/key',{'access_token' => 'access_token'}
    expect(last_response.body).to eq("xyz")
  end

  it "should update value for an existing key" do
  	body = { :key => "123"}.to_json 
    post '/api/v1/object?access_token=access_token', body, {'Content-Type' => 'application/json'}
  	$time_updated = Time.now.to_i
    expect(last_response).to be_ok
  end

  it "should accept a key return recent value" do
    get '/api/v1/object/key',{'access_token' => 'access_token'}
    expect(last_response.body).to eq("123")
  end

  it "should accept a key with timestamp and return a value" do

  	#get value and timestamp of an existing key
  	get '/api/v1/object/Ben',{'access_token' => 'access_token'}
  	old_value = last_response.body
  	key= Objects.where(:key => "Ben").first
  	t=Timedobjects.where(:key_id => key.id).last.timestamp
  	old_value = Timedobjects.where(:key_id => key.id).last.key_value

    #update the key with new value
    body = { :Ben => "New_Value"}.to_json 
    post '/api/v1/object?access_token=access_token', body, {'Content-Type' => 'application/json'}
    
    get '/api/v1/object/Ben',{'access_token' => 'access_token', 'timestamp'=> t.to_i}
    expect(last_response.body).to eq(old_value)
  end

  it "should throw unauthorised error for unknown user " do
    get '/api/v1/object/key',{'access_token' => 'unknown access token'}
    expect(last_response.body).to include("Unauthorized!")
  end

  it "should throw invalid params error when given key is not present " do
    get '/api/v1/object/unknown_key',{'access_token' => 'access_token'}
    expect(last_response.body).to include("Invalid request parameters")
  end

  it "should store key and value" do
		body = { :Ben => ""}.to_json 
    post '/api/v1/object?access_token=access_token', body, {'Content-Type' => 'application/json'}
    expect(last_response).to be_ok
  end

end