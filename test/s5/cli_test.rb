require 'test_helper'

class S5::CliTest < S5::Test
  def test_observe_directory
    daemon = S5::Cli.new.observe(fixtures_path.to_s)
    assert daemon.pid
    sleep 0.1
    daemon.stop
  end
end
