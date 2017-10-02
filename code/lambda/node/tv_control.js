var exec = require('child_process').exec;

exports.handler = function(event, context) {
  exec("./lib/ruby/bin/ruby tv_control.rb '" + JSON.stringify(event) + "'", function(error, stdout, stderr) {
    context.succeed(JSON.parse(stdout));
  });
};
