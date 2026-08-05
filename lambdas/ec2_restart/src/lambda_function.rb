require 'aws-sdk-ec2'
require 'aws-sdk-ssm'
require 'base64'
require 'openssl'
require 'cgi'
require 'json'

class Ec2RestartService
  REPLY_DEFENCE_LIMIT = 300
  CRYPTOGRAPHIC_ALGORITHM = 'sha256'

  def initialize(event)
    @event = event
  end

  def call
    load_env_variables
    parse_params
    return respond_to_slack("❌ *Помилка авторизації*") unless signed_request?
    return respond_to_slack("❌ *Неавторизований канал*") unless params['channel_id'] == slack_channel_id

    puts "ALERT: User #{params['user_name']}(##{params['user_id']}) triggered EC2 reboot for #{ec2_instance_id}"
    Aws::EC2::Client.new(region: ec2_region)
                    .reboot_instances(instance_ids: [ec2_instance_id])
    respond_to_slack("🚀 Production інстанс(ID `#{ec2_instance_id}`) успішно відправлено на перезавантаження!")
  rescue Aws::EC2::Errors::ServiceError => e
    respond_to_slack("❌ **AWS Помилка**: #{e.message}")
  rescue StandardError => e
    respond_to_slack("⚠️ **Системна помилка**: #{e.message}")
  end

  private

  attr_reader :event, :params, :ec2_region, :slack_signing_secret, :slack_channel_id, :ec2_instance_id

  def load_env_variables
    @ec2_region = load_env_variable(ENV['EC2_REGION_PATH'])
    @slack_signing_secret = load_env_variable(ENV['SLACK_SIGNING_SECRET_PATH'], with_decryption: true)
    @slack_channel_id = load_env_variable(ENV['SLACK_CHANNEL_ID_PATH'])
    @ec2_instance_id = load_env_variable(ENV['TARGET_INSTANCE_ID_PATH'])
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
    event['isBase64Encoded'] ? Base64.decode64(event['body']) : event['body']
  end

  def signed_request?
    slack_signature = event.dig('headers', 'x-slack-signature') || event.dig('headers', 'X-Slack-Signature')
    timestamp = event.dig('headers', 'x-slack-request-timestamp') || event.dig('headers', 'X-Slack-Request-Timestamp')

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
end

def lambda_handler(event:, context:)
  Ec2RestartService.new(event)
                   .call
end
