require 'sinatra'
require 'sinatra-websocket'
require 'aws-sdk-apigateway'
require 'faraday_middleware'
require 'faraday_middleware/aws_sigv4'
require 'amazing_print'

AWS_REGION = 'us-east-1'
API_ID     = '9ucus3fwwj'
ws_url     = "wss://#{API_ID}.execute-api.#{AWS_REGION}.amazonaws.com/test"
#             wss://9ucus3fwwj.execute-api.us-east-1.amazonaws.com/test
app_url    = 'https://console.aws.amazon.com/cloud9/ide/066180cd4f524733bb998679cfa1e14a'
hit_count  = 0

ENV['AWS_ACCESS_KEY_ID']     || (puts('No env var AWS_ACCESS_KEY_ID'); exit)
ENV['AWS_SECRET_ACCESS_KEY'] || (puts('No env var AWS_SECRET_ACCESS_KEY'); exit)
RANDYS_IP = '136.55.5.229'

set :bind, '0.0.0.0'
set :port, 8081
set :sockets, []
puts "\nServer listening on '/' for connection to:"
puts app_url
puts "...using websocket:"
puts ws_url
puts '...'

def log_randy
  ip = request.ip
  return unless request.websocket?
  #return unless (ip == RANDYS_IP) || (ip == '127.0.0.1')

  puts "#{'---'*9}"
  ap request.env, options = {}
  puts "#{'---'*9}"
end


get '/' do
  hit_count += 1
  puts "ws_toy received '/', hit # #{hit_count}, from #{request.ip}"
  log_randy
end


get '/rjp' do
  hit_count += 1
  log_randy
  ip = request.ip
  "websocket_toy says OK to hit # #{hit_count} from #{ip}, but without using an actual websocket"
end


get '/speak' do
  hit_count += 1
  puts "ws_toy received /speak, hit # #{hit_count}, from #{request.ip}"
  log_randy
  if !request.websocket?
    "ws_toy is replying to a non-websocket request to '/', hit # #{hit_count}"
  else
    request.websocket do |ws|
      ws.onopen do
        ws.send "ws_toy says Hi, because it recognized a websocket request, hit # #{hit_count}"
        settings.socket << ws
      end
      ws.onmessage do |msg|
        EM.next_tick { settings.sockets.each{|s| s.send(msg) } }
      end
      ws.onclose do
        warn("websocket closed")
        settings.sockets.delete ws
      end
    end
  end
end


get '/default' do
  hit_count += 1
  puts "ws_toy received /default, hit # #{hit_count}, from #{request.ip}"
  log_randy
end

=begin
  client = Aws::APIGateway::Client.new(region: AWS_REGION)
  conn   = Faraday.new(url: ws_url) do |cfg|
             cfg.request :aws_sigv4,
                         service: 'apigateway',
                         region:   AWS_REGION,
                         access_key_id:     ENV['AWS_ACCESS_KEY_ID'],
                         secret_access_key: ENV['AWS_SECRET_ACCESS_KEY']
             cfg.response :json, :content_type => /\bjson\b/
             cfg.response :raise_error
             cfg.adapter Faraday.default_adapter
           end
  resp = conn.get '/test' || 'No response, but no errors either'
  "resp --> #{resp.inspect}"
#end
=end

=begin
class AwsGateway
  def connection
    Faraday.new(url: @url) do |cfg|
      cfg.headers['Content-Type'] = "application/json"
      opts = cfg.options
      opts.timeout = 5
      opts.open_timeout = 2
      cfg.response :json, content_type: /\bjson\b/
      cfg.request :retry, max: 2, interval: 0.05, backoff_factor: 2
      cfg.request:aws_signers_v4,
        credentials: Aws:Credentials.new(aws_access_key_id, aws_access_key),
        service_name: 'apigateway',
        region: 'us-east-1'
      cfg.adapter Faraday.default_adapter
    end
  end
=end
