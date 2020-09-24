require 'sinatra'

AWS_REGION = 'us-east-1'

get '/' do
  'OK'
end

get '/aws_websocket_replies' do
  # When the "credentials: foo" config is omitted, the AWS gem looks in ~/.aws/credentials
  client = Aws::ApiGatewayV2::Client.new(region: AWS_REGION)
  'not yet'
end


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
end
