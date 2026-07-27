require 'aws-sdk-ec2'
require 'json'

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

  query_params = event['queryStringParameters'] || {}
  incoming_secret = query_params['secret']
  return respond_to_slack("❌ **Помилка авторизації**") unless incoming_secret == ENV['SLACK_SIGNING_SECRET']

  ec2.reboot_instances(instance_ids: [target_instance_id])
  respond_to_slack("🚀 Інстанс `#{target_instance_id}` успішно відправлено на перезавантаження!")
rescue Aws::EC2::Errors::ServiceError => e
  respond_to_slack("❌ **AWS Помилка**: #{e.message}")
rescue StandardError => e
  respond_to_slack("⚠️ **Системна помилка**: #{e.message}")
end
