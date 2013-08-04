require "aws-sdk"

module S5
  autoload :Cli,     's5/cli'
  autoload :Daemon,  's5/daemon'
  autoload :Sync,    's5/sync'
  autoload :VERSION, 's5/version'
end
