require 'test_helper'

class S5::CliTest < MiniTest::Test
  def setup
    @fixtures_path = File.expand_path('../../fixtures', __FILE__)
  end

  def test_observe_directory
    daemon = S5::Cli.new.observe(@fixtures_path)
    assert daemon.pid
    sleep 0.1
    daemon.stop
  end
end
