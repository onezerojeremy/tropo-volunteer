%w(rubygems sinatra tropo-webapi-ruby open-uri json/pure helpers.rb).each{|lib| require lib}

# For the Web UI
set :views, File.dirname(__FILE__) + '/templates'
set :public, File.dirname(__FILE__) + '/public'
set :haml, { :format => :html5 }

# To manage the web session coookies
use Rack::Session::Pool

# Resource called by the Tropo WebAPI URL setting
post '/index.json' do
  # Fetches the HTTP Body (the session) of the POST and parse it into a native Ruby Hash object
  v = Tropo::Generator.parse request.env["rack.input"].read
  
  # Fetching certain variables from the resulting Ruby Hash of the session details
  # into Sinatra/HTTP sessions; this can then be used in the subsequent calls to the
  # Sinatra application
  session[:from] = v[:session][:from]
  session[:network] = v[:session][:to][:network]
  session[:channel] = v[:session][:to][:channel]
  
  # Create a Tropo::Generator object which is used to build the resulting JSON response
  t = Tropo::Generator.new
    # If there is Initial Text available, we know this is an IM/SMS/Twitter session and 
    # not voice
  t.say => "Hello Dolly"
  
  
##################
### WEB ROUTES ###
##################
get '/' do
  haml :index
end

get '/stylesheets/style.css' do
  content_type 'text/css', :charset => 'utf-8'
  sass :style
end

get '/stylesheets/fonts.css' do
  content_type 'text/css', :charset => 'utf-8'
  sass :fonts
end