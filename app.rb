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
    if v[:session][:initial_text]
      # Add an 'ask' WebAPI method to the JSON response with appropriate options
      t.ask :name => 'initial_text', :choices => { :value => "[ANY]"}
      # Set a session variable with the zip the user sent when they sent the IM/SMS/Twitter 
      # Request
      session[:zip] = v[:session][:initial_text]
    else
      # If this is a voice session, then add a voice-oriented ask to the JSON response
      # with the appropriate options
      t.ask :name => 'zip', :bargein => true, :timeout => 180, :attempts => 2,
          :say => [{:event => "timeout", :value => "Sorry, I did not hear anything."},
                   {:event => "nomatch:1 nomatch:2", :value => "Oops, that was not a five-digit zip code."},
                   {:value => "Please enter your adddress or zip code to search for stores in your area that accept food assistance cards."}],
                    :choices => { :value => "[ANY]"}
    end      
    
    # Add a 'hangup' to the JSON response and set which resource to go to if a Hangup event occurs on Tropo
    t.on :event => 'hangup', :next => '/hangup.json'
    # Add an 'on' to the JSON response and set which resource to go when the 'ask' is done executing
   # t.on :event => 'continue', :next => '/process_zip.json'
  
  # Return the JSON response via HTTP to Tropo
  t.hangup
end


# The next step in the session is posted to this resource when any of the resources do a hangup
post '/hangup.json' do
  v = Tropo::Generator.parse request.env["rack.input"].read
  puts " Call complete (CDR received). Call duration: #{v[:result][:session_duration]} second(s)"
end

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