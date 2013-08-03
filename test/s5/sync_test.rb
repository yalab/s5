require 'test_helper'

class S5::SyncTest < MiniTest::Test
  def setup
    @encrypt_key_path = S5::Sync.encrypt_key_path
    @encrypt_key_path_backup = @encrypt_key_path + '.s5_test'
    if File.exists?(@encrypt_key_path)
      FileUtils.mv @encrypt_key_path, @encrypt_key_path_backup
    end
    @bucket_name = "#{ENV['USER']}-s5-test"
    @sync ||= S5::Sync.new(bucket_name: @bucket_name)
  end

  def teardown
    if File.exists?(@encrypt_key_path_backup)
      FileUtils.mv @encrypt_key_path_backup, @encrypt_key_path
    end
    AWS.s3.buckets[@bucket_name].objects.delete_all
  end

  def test_encrypt_key_path
    assert_equal ENV['HOME'] + '/.s5.key', S5::Sync.encrypt_key_path
  end

  module SyncPutTest
    def test_sync_put
      s3_object = @sync.put(@path)
      assert_equal @plain, s3_object.read
    end

    def test_sync_put_with_encrypt
      @sync.encrypt!
      assert File.exists?(S5::Sync.encrypt_key_path)
      s3_object = @sync.put(@path)
      refute_equal @plain, s3_object.read
      assert_equal @plain, s3_object.read(encryption_key: File.binread(@encrypt_key_path))
    end
  end

  class SinglePathTest < self
    include SyncPutTest
    def setup
      super
      @plain = Digest::SHA2.hexdigest(Time.now.to_f.to_s) + 'test'
      @path = File.expand_path('../../fixtures/test.txt', __FILE__)
      FileUtils.mkdir_p File.dirname(@path)
      File.open(@path, 'w') do |f|
        f.write @plain
      end
    end

    def test_default_bucket_name
      assert_match '-s5sync', S5::Sync.new.bucket_name
    end
  end

  class RelativePathTest < self
    include SyncPutTest
    def setup
      super
      @plain = Digest::SHA2.hexdigest(Time.now.to_f.to_s) + 'test'
      @relative = 'fixtures/test.txt'
      @basedir = File.expand_path('../../', __FILE__)
      @path = @basedir + '/'  + @relative
      FileUtils.mkdir_p File.dirname(@path)
      File.open(@path, 'w') do |f|
        f.write @plain
      end
    end

    def test_object_path
      s3_object = @sync.put(@relative, @basedir)
      assert_equal @relative, s3_object.key
    end
  end
end
