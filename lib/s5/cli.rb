require 'thor'
require 's5'

class S5::Cli < Thor
  class_option :help, type: :boolean, aliases: '-h', desc: 'Print help message.'

  desc "observe DIRECTORIES", "Observe the DIRECTORIES to sync S3"
  method_option :bucket, type: :string, default: nil, aliases: '-b', desc: 'Set bucket name.'
  def observe(directory)
    if options[:help]
      S5::Cli.command_help(shell, 'observe')
      exit
    end
    daemon = S5::Daemon.new(directory, bucket_name: options[:bucket])
    daemon.start
    daemon
  end
end
