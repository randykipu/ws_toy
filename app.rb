require 'sinatra'
require 'aws-sdk-apigateway'
require 'faraday_middleware'
require 'faraday_middleware/aws_sigv4'

AWS_REGION = 'us-east-1'
API_ID     = '9ucus3fwwj'
WS_URL     = "wss://9ucus3fwwj.execute-api.us-east-1.amazonaws.com"
#    wss://9ucus3fwwj.execute-api.us-east-1.amazonaws.com

ENV['AWS_ACCESS_KEY_ID']    || (puts('No env var AWS_ACCESS_KEY_ID'); exit)
ENV['AWS_SECRET_ACCESS_KEY'] || (puts('No env var AWS_SECRET_ACCESS_KEY'); exit)

get '/' do
  'websocket_toy says OK, but without using an actual websocket'
end

get '/aws_websocket_replies' do
    # {"credentials: foo"} config is omitted, so AWS gem looks in ~/.aws/credentials
  client = Aws::APIGateway::Client.new(region: AWS_REGION)
  app_url = 'https://console.aws.amazon.com/cloud9/ide/066180cd4f524733bb998679cfa1e14a'
  ws_url  = "wss://#{API_ID}.execute-api.#{AWS_REGION}.amazonaws.com"
  conn = Faraday.new(url: ws_url) do |cfg|
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
end


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
