require 'test_helper'

class S5::BootstrapTest < S5::Test
  def setup
    bucket_name = "#{ENV['USER']}-s5-test-bootstrap"
    s3 = AWS.s3
    @bucket = s3.buckets.create(bucket_name)
    @local_dir = File.expand_path('../../bootstrap_test', __FILE__)
    setup_local
    setup_remote
    @sync = S5::Sync.new(local_path: @local_dir, remote_bucket: bucket_name)
  end

  def teardown
    @bucket.delete!
    FileUtils.rm_rf(@local_dir)
  end

  def setup_remote
    @remote_object_name = 'remote'
    object = @bucket.objects[@remote_object_name].write("remotetest")
    @last_modified = object.last_modified
  end

  def setup_local
    @local_file_name = 'local.txt'
    FileUtils.mkdir_p(@local_dir)
    File.open(@local_dir + "/#{@local_file_name}", 'w') do |f|
      f.write("localtest")
      @mtime = f.mtime
    end
  end

  def test_remote_list
    expect = {@remote_object_name => @last_modified}
    assert_equal expect, @sync.remote_list
  end

  def test_local_list
    FileUtils.mkdir_p(@local_dir + '/dir')
    expect = {@local_file_name => @mtime}
    assert_equal expect, @sync.local_list
  end

  def test_sync!
    @sync.sync!
    assert_equal @sync.remote_list.keys.sort, @sync.local_list.keys.sort
  end
end
