require 'sinatra'
require "sinatra/namespace"
require 'pg'
require 'active_record'
require 'json'
require 'securerandom'

class Objects < ActiveRecord::Base
	validate :key, presence: true
	validate :value, presence: true
end

class Timedobjects < ActiveRecord::Base
	validate :key_id, presence: true
	validate :key_value, presence: true
end

class Apikeys < ActiveRecord::Base
	before_create :generate_access_token

	private

	def generate_access_token
		begin
		  self.access_token = SecureRandom.hex
		end while self.class.exists?(access_token: access_token)
	end
end

class MyApi < Sinatra::Base
  register Sinatra::Namespace

   ### connecting to database ###
	begin
		ActiveRecord::Base.establish_connection(
			"postgres://mmcowkbdkruwoj:8O7kwduHwfnWX2J_zh3DkPuJPA@ec2-54-235-123-19.compute-1.amazonaws.com:5432/de2irj3vrcjj56"
		  
		)
	rescue ActiveRecord::ActiveRecordError => e
		puts "DATABASE CONNECTION ERROR"
		puts e.message
	end

	namespace '/api/v1' do
        
    #Authenticate user 
		before do
			api_key = Apikeys.find_by_access_token(params[:access_token])
			halt 401, {"status"=>"failed", "content"=>"Unauthorized! "}.to_json unless api_key
    end


		### Method: GET /object/mykey ###
		### Method: GET /object/mykey?timestamp= ###
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

			rescue ActiveRecord::StatementInvalid => e
		    halt 500, {"status"=>"failed", "content"=>"Failed to get requested object! #{e.message}"}.to_json
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
		    	halt 400, {'status' => {'errors' => Array.new(1, "Request parameter parsing failure! #{o_parser_error.message}")}, 'content'=>''}.to_json
		    end
		  else
		  		halt 405, {'status' => {'errors' => Array.new(1, "HTTP #{request.request_method} Method Not Allowed")}, 'content'=>''}.to_json
		  end

		end

		### Method: POST /object ###
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
		    halt 500, {"status"=>"failed", "content"=>"Failed to create new record! #{e.message}"}.to_json
			end
		end
	end

	### close database connection ###
	after do
		ActiveRecord::Base.connection.close
	end
end
MyApi.run!
