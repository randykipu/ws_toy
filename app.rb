require 'sinatra'
require 'aws-sdk-apigateway'
require 'faraday_middleware'
require 'faraday_middleware/aws_signers_v4'

AWS_REGION = 'us-east-1'
API_ID     = '9ucus3fwwj'

get '/' do
  'websocket_toy says OK, but without using an actual websocket'
end

get '/aws_websocket_replies' do
    # {"credentials: foo"} config is omitted, so AWS gem looks in ~/.aws/credentials
  client = Aws::APIGateway::Client.new(region: AWS_REGION)
  app_url = 'https://console.aws.amazon.com/cloud9/ide/066180cd4f524733bb998679cfa1e14a'
  ws_url  = "wss://#{API_ID}.execute-api.#{AWS_REGION}.amazonaws.com"
  conn = Faraday.new(url: ws_url) do |cfg|
           cfg.request :aws_signers_v4,  credentials: creds,
                       service_name: 'execute-api',  region: AWS_REGION
           cfg.response :json, :content_type => /\bjson\b/
           cfg.response :raise_error
           cfg.adapter Faraday.default_adapter
         end
  resp = conn.get '/test'
  #'Not yet implemented, but at least the method does not fail'
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
