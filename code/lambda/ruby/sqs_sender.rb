$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'aws-sigv4'
require 'net/http'
require 'json'

def send_to_sqs(key, secret, queue, message)
  url = queue + "?Action=SendMessage&MessageBody=#{URI.encode_www_form_component(message)}"
  signer = Aws::Sigv4::Signer.new(
    service: 'sqs',
    region: queue.split('.')[1],
    access_key_id: key,
    secret_access_key: secret
  )
  signed_url = signer.presign_url(http_method: "GET", url: url)

  uri = URI.parse(queue)
  https = Net::HTTP.new(uri.host, uri.port)
  https.use_ssl = true
  request = Net::HTTP::Get.new(signed_url)
  https.request(request)
end

key = ENV["KEY"]
secret = ENV["SECRET"]
queue = ENV["SQS_QUEUE"]

event = JSON.parse(ARGV[0])
name = event["request"]["intent"]["slots"]["name"]["value"]
send_to_sqs(key, secret, queue, name)

STDOUT.puts({
  version: "1.0", 
  response: {
    outputSpeech: {
      type: "PlainText", 
      text: "I heard you say #{name}." 
    }, 
    shouldEndSession: true
  }
}.to_json)
