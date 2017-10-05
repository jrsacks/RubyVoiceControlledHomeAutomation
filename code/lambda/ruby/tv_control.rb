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

def lookup_channel(val)
  return val.to_s if val.to_i > 0
  channels = {
    "cbs" => 602, "nbc" => 605, "abc" => 607,
    "wgn" => 609, "fox" => 612, "espn" => 681,
    "espn2" => 682 
  }
  channels[val.downcase].to_s
end

key = ENV["KEY"]
secret = ENV["SECRET"]
queue = ENV["SQS_QUEUE"]

event = JSON.parse(ARGV[0])
intent = event["request"]["intent"]
intent_name = intent["name"]

commands = {
  "Off"               => "/tv/power/off",
  "VolUp"             => "/tv/volume/up",
  "VolDown"           => "/tv/volume/down",
  "Mute"              => "/tv/mute",
  "UnMute"            => "/tv/unmute",
  "Back"              => "/tivo/IRCODE/ENTER",
  "VolSet"            => "/tv/volume/",
  "ChangeChannel"     => "/tivo/ch/"
}

responses = {
  "Off"               => "Now Turning off the TV",
  "VolUp"             => "Turning Volume Up",
  "VolDown"           => "Turning Volume Down",
  "Mute"              => "Muting",
  "UnMute"            => "Unmuting",
  "Back"              => "Switching Back",
  "VolSet"            => "Changing the volume to ",
  "ChangeChannel"     => "Changing the channel to "
}

command = commands[intent_name]
alexa_response = responses[intent_name]

if intent_name == "VolSet"
  volume = intent["slots"]["Volume"]["value"].to_s
  command += volume
  alexa_response += volume
end

if intent_name == "ChangeChannel"
  channel = intent["slots"]["Channel"]["value"]
  channel_number = lookup_channel(channel)
  command += channel_number
  alexa_response += channel_number
end

send_to_sqs(key, secret, queue, command)

STDOUT.puts({
  version: "1.0", 
  response: {
    outputSpeech: {
      type: "PlainText", 
      text: alexa_response
    }, 
    shouldEndSession: true
  }
}.to_json)
