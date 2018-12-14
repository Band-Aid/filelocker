require 'boxr'
require 'sinatra'
require 'dotenv'
require 'redis'
require 'rest-client'
set :protection, :except => :frame_options
use Rack::Session::Cookie, :key => 'SESSION_ID',
                           :expire_after => 360,
                           :secret => Digest::SHA256.hexdigest(rand.to_s)

before do   # Before every request, make sure they get assigned an ID.
    session[:id] ||= SecureRandom.uuid
end



	def getToken(code)
	    
	    
	    begin
	        res = RestClient.post('https://api.box.com/oauth2/token/', {grant_type: 'authorization_code', code: code, client_id: 'hvrjuf6ml4r0u7mzpz64rkqweb3mwtyw', client_secret: 'SL5oiItCuRgVE79Op6NwSM37PQJPUEuy'})
	        parsed = JSON.parse(res.body)
	        obj = Hashie::Mash.new parsed
	        atoken = obj.access_token
	    rescue Exception => e
	        return "アクセストークンを取得できませんでした。アプリ開発者に問い合わせてください。"
	    end
	    return atoken
	    
	end



    def initcheck(folderid,atoken)

    	
 		client = Boxr::Client.new atoken
        items = client.folder_items(folderid)
        items.each {|i|
        #puts i.name  + " will become open shared link"
            if i.type == 'folder'
                folderlist(i.id,atoken)
            else
                lockfiles(i.id,atoken)
            end
    #$client.create_shared_link_for_file(i.id, access: :open)
    }
    return "done"
    end


    def lockfiles(fileid,atoken)
    	
    	
    	client = Boxr::Client.new atoken
        if client.file_from_id(fileid,fields: ['lock']).lock == nil
            t = Time.now + 3600
            client.lock_file(fileid,expires_at: t)
        else 
            client.unlock_file(fileid)
        end
    end

    def folderlist(folderid,atoken)
        initcheck(folderid,atoken)
    end
    
	post '/lock_request' do
	    @folderid = params[:folderid]
	   # folderid = "42926117802"
	    @session = session[:id]
	    @code = params[:code]
	    @atoken = getToken(@code)
	   
	    #token = getToken(code)
	    #atoken = "iRqYBqtnNaf1ed4pubVM64QFU982xAgH"
	    return erb :home
	end
	
	post '/go' do
	   # @locktime = params[:locktime]
	    atoken = params[:atoken]
	    folderid = params[:folderid]
	    initcheck(folderid, atoken)
	
	end
	
	get '/' do
	    return erb :home
	end
