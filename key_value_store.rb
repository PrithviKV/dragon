require 'sinatra'
require 'pg'
require 'active_record'
require 'JSON'

begin

	ActiveRecord::Base.establish_connection(
	  "postgres://mmcowkbdkruwoj:8O7kwduHwfnWX2J_zh3DkPuJPA@ec2-54-235-123-19.compute-1.amazonaws.com:5432/de2irj3vrcjj56"
	)
rescue
	puts "DATABASE CONNECTION ERROR"
end

class Objects < ActiveRecord::Base
	GET_VALUE_WITH_TIMESTAMP_REQUIRED_PARAMS=['api_key', 'timestamp', 'key']
end

class Timedobjects < ActiveRecord::Base
end

before '/object/:key' do
  if request.request_method == 'GET'
  	if not Objects.all.pluck(:key).include? params['key']
  		halt 400, {'status' => {'errors' => Array.new(1, "Invalid request parameters;")}, 'content'=>''}.to_json
  	end
  else
    halt 405, {'status' => {'errors' => Array.new(1, "HTTP #{request.request_method} Method Not Allowed")}, 'content'=>''}.to_json
  end

end

get '/object/:key' do

	r = nil
	begin

		p = Objects.find_by_key("#{params['key']}")

		if !p
			halt 404, {'status' => {'errors' => Array.new(1, "Invalid key")}, 'content'=>''}.to_json
    end

		if !params[:timestamp].nil?
			t = params[:timestamp].to_i

			v = Timedobjects.where('key_id = ? AND timestamp <= ?',p.id,Time.at(t)).last
	    r = v.key_value if v
	  else
	    
	    r = p.value if p
     end 

	rescue ActiveRecord::StatementInvalid
    halt 500, {"status"=>"failed", "content"=>"Failed to get requested object!"}.to_json
	end

	if r.nil?
	  halt 404, {'status' => {'errors' => Array.new(1, "Object Not Found")}, 'content'=>''}.to_json
  end

  return r
end


before '/object' do
  if request.request_method == 'POST'
    begin
      request.body.rewind
      request_body_params = JSON.parse(request.body.read)
      params.merge!(request_body_params)
    rescue JSON::ParserError => o_parser_error
      halt 400, {'status' => {'errors' => Array.new(1, 'Request parameter parsing failure!')}, 'content'=>''}.to_json
    end
  else
    halt 405, {'status' => {'errors' => Array.new(1, "HTTP #{request.request_method} Method Not Allowed")}, 'content'=>''}.to_json
  end
end


post '/object' do
	request.body.rewind
	request_body_params = JSON.parse(request.body.read)
	key = request_body_params.keys[0]
	value = request_body_params["#{key}"]
	p = nil

  begin
	  p = Objects.find_by_key("#{key}")
	  if !p
	  	p = Objects.new(key: "#{key}", value: "#{value}")
	  	p.save
	  else
	    p.update(value: "#{value}")
	  end
	  t = Timedobjects.new(key_id: p.id, key_value: "#{value}",timestamp: Time.now.change(:usec => 0))
	  t.save
	rescue ActiveRecord::StatementInvalid => e
		puts e.message
    halt 500, {"status"=>"failed", "content"=>"Failed to create new record!"}.to_json
	end
end

after do
  ActiveRecord::Base.connection.close
end