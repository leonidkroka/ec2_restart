require 'aws-sdk-ec2'
require 'base64'
require 'openssl'
require 'cgi'
require 'json'

REPLY_DEFENCE_LIMIT = 300
CRYPTOGRAPHIC_ALGORITHM = 'sha256'

def sighed_request?(event)
  slack_signature = event.dig('headers', 'x-slack-signature') || event.dig('headers', 'X-Slack-Signature')
  timestamp = event.dig('headers', 'x-slack-request-timestamp') || event.dig('headers', 'X-Slack-Request-Timestamp')

  return false if slack_signature.nil? || timestamp.nil?
  return false if (Time.now.to_i - timestamp.to_i).abs > REPLY_DEFENCE_LIMIT

  body = Base64.decode64(event['body'])
  signature_base_string = "v0:#{timestamp}:#{body}"

  expected_signature = 'v0=' + OpenSSL::HMAC.hexdigest(
    OpenSSL::Digest.new(CRYPTOGRAPHIC_ALGORITHM),
    ENV['SLACK_SIGNING_SECRET'],
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

def lambda_handler(event:, context:)
  ec2 = Aws::EC2::Client.new(region: ENV['EC2_REGION'])
  target_instance_id = ENV['TARGET_INSTANCE_ID']

  params = CGI.parse(Base64.decode64(event['body'])).transform_values(&:first)
  return respond_to_slack("❌ **Помилка авторизації**") unless sighed_request?(event)
  return respond_to_slack("❌ **Неавторизований канал**") unless params['channel_id'] == ENV['SLACK_CHANNEL_ID']

  puts "ALERT: User #{params['user_name']}(##{params['user_id']}) triggered EC2 reboot for #{target_instance_id}"
  ec2.reboot_instances(instance_ids: [target_instance_id])
  respond_to_slack("🚀 Інстанс `#{target_instance_id}` успішно відправлено на перезавантаження!")
rescue Aws::EC2::Errors::ServiceError => e
  respond_to_slack("❌ **AWS Помилка**: #{e.message}")
rescue StandardError => e
  respond_to_slack("⚠️ **Системна помилка**: #{e.message}")
end
