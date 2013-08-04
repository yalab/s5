require 'thor'

class S5::Cli < Thor
  desc "observe DIRECTORIES", "Observe the DIRECTORIES to sync S3"
  def observe(directory)
    daemon = S5::Daemon.new(directory)
    daemon.start
    daemon
  end
end
