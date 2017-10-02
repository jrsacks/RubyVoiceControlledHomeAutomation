require 'json'

STDOUT.puts({
  version: "1.0", 
  response: {
    outputSpeech: {
      type: "PlainText", 
      text: "Hello from Ruby." 
    }, 
    shouldEndSession: true
  }
}.to_json)
