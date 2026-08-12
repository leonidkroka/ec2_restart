require 'aws-sdk-ssm'
require 'base64'
require 'openssl'
require 'cgi'
require 'net/http'
require 'uri'
require 'json'

Zone = Struct.new(:id, :name)

class CachePurgeService
  REPLY_DEFENCE_LIMIT = 300
  CRYPTOGRAPHIC_ALGORITHM = 'sha256'
  CLOUDFLARE_API_URL = 'https://api.cloudflare.com/client/v4/zones/%{zone_id}/purge_cache'

  def initialize(event)
    @event = event
  end

  def call
    load_env_variables
    parse_params
    return respond_to_slack("❌ *Помилка авторизації*") unless signed_request?
    return respond_to_slack("❌ *Неавторизований канал*") unless params['channel_id'] == slack_channel_id

    puts "ALERT: User #{params['user_name']}(##{params['user_id']}) triggered Cloudflare cache purge for zone #{zone.name} (#{zone.id})"

    send_cloudflare_request
    respond_to_slack("🚀 **Cloudflare кєш успішно очищено!** (Purge Everything) (##{zone.name})")
  rescue SocketError, Net::OpenTimeout, Net::ReadTimeout => e
    respond_to_slack("❌ **Cloudflare Помилка мережі**: #{e.message} (##{zone.name})")
  rescue StandardError => e
    puts "ERROR: #{e.class} - #{e.message}\n#{e.backtrace.join("\n")}"
    respond_to_slack("⚠️ **Системна помилка**: #{e.message}")
  end

  private

  attr_reader :event, :params,
              :cloudflare_zone_id, :cloudflare_secondary_zone_id, :cloudflare_api_token,
              :slack_signing_secret, :slack_channel_id

  def load_env_variables
    @cloudflare_zone_id = load_env_variable(ENV['CF_ZONE_ID_PATH'])
    @cloudflare_secondary_zone_id = load_env_variable(ENV['CF_SECONDARY_ZONE_ID_PATH'])
    @cloudflare_api_token = load_env_variable(ENV['CF_API_TOKEN_PATH'], with_decryption: true)
    @slack_signing_secret = load_env_variable(ENV['SLACK_SIGNING_SECRET_PATH'], with_decryption: true)
    @slack_channel_id = load_env_variable(ENV['SLACK_CHANNEL_ID_PATH'])
  end

  def load_env_variable(path, with_decryption: false)
    ssm_client.get_parameter(name: path, with_decryption: with_decryption)
              .parameter
              .value
  end

  def ssm_client
    @ssm_client ||= Aws::SSM::Client.new(region: ENV['SSM_REGION'])
  end

  def parse_params
    @params = CGI.parse(raw_body).transform_values(&:first)
  end

  def raw_body
    event['isBase64Encoded'] ? Base64.decode64(event['body'] || '') : (event['body'] || '')
  end

  def signed_request?
    headers = event['headers'] || {}
    slack_signature = headers['x-slack-signature'] || headers['X-Slack-Signature']
    timestamp = headers['x-slack-request-timestamp'] || headers['X-Slack-Request-Timestamp']

    return false if slack_signature.nil? || timestamp.nil?
    return false if (Time.now.to_i - timestamp.to_i).abs > REPLY_DEFENCE_LIMIT

    signature_base_string = "v0:#{timestamp}:#{raw_body}"

    expected_signature = 'v0=' + OpenSSL::HMAC.hexdigest(
      OpenSSL::Digest.new(CRYPTOGRAPHIC_ALGORITHM),
      slack_signing_secret,
      signature_base_string
    )
    return false unless expected_signature.bytesize == slack_signature.bytesize

    OpenSSL.fixed_length_secure_compare(expected_signature, slack_signature)
  end

  def respond_to_slack(message)
    {
      statusCode: 200,
      headers: { 'Content-Type' => 'application/json' },
      body: JSON.generate(
        {
          response_type: 'ephemeral',
          text: message
        }
      )
    }
  end

  def send_cloudflare_request
    uri = URI(CLOUDFLARE_API_URL % { zone_id: zone.id })
    payload = { purge_everything: true }

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    request['Authorization'] = "Bearer #{cloudflare_api_token}"
    request.body = payload.to_json

    response = http.request(request)
    body = JSON.parse(response.body) rescue {}

    return if body['success'] == true

    error_msg = body.dig('errors', 0, 'message') || "HTTP #{response.code}: #{response.message}"
    raise error_msg
  end

  def zone
    @zone ||= if secondary_domain?
                Zone.new(cloudflare_secondary_zone_id, 'design')
              else
                Zone.new(cloudflare_zone_id, 'main')
              end
  end

  def secondary_domain?
    query_params = event['queryStringParameters'] || {}
    query_params['cache_type'] == 'secondary'
  end
end

def lambda_handler(event:, context:)
  CachePurgeService.new(event).call
end