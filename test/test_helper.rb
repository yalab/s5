require 'minitest/autorun'
require 'minitest/pride'
require 'digest/sha2'
require 'fileutils'
require 's5'

class S5::Test < MiniTest::Test
  def setup
    @fixtures_path ||= Pathname.new(File.expand_path('../fixtures', __FILE__)).tap{|path|
      FileUtils.mkdir_p path.to_s
    }
  end

  def teardown
    FileUtils.rm_rf(@fixtures_path)
  end
end
