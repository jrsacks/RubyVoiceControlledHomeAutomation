require 'json'

event = JSON.parse(ARGV[0])
name = event["request"]["intent"]["slots"]["name"]["value"]

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
