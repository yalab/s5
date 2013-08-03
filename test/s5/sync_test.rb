require 'test_helper'

class S5::SyncTest < MiniTest::Unit::TestCase
  def setup
    @plain = Digest::SHA2.hexdigest(Time.now.to_f.to_s)
    @path = File.expand_path('../../fixtures/test.txt', __FILE__)
    FileUtils.mkdir_p File.dirname(@path)
    File.open(@path, 'w') do |f|
      f.puts @plain
    end
    @sync = S5::Sync.new(@path)
  end

  def test_default_bucket_name
    assert_match '-s5sync', @sync.bucket
  end

  def test_sync_run
    s3_object = @sync.run
    assert_equal @plain, s3_object.read.chop
  end
end
