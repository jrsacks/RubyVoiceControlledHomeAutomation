exports.handler = function(event, context) {
  context.succeed({
    version: "1.0", 
    response: {
      outputSpeech: {
        type: "PlainText",
        text: "Hello Ruby Conf.  I'm glad this demo worked!" 
      }, 
      shouldEndSession: true
    }
  });
};
