require 'test_helper'

class S5::SyncTest < S5::Test
  def setup
    @encrypt_key_path = S5::Sync.encrypt_key_path
    @encrypt_key_path_backup = @encrypt_key_path + '.s5_test'
    if File.exists?(@encrypt_key_path)
      FileUtils.mv @encrypt_key_path, @encrypt_key_path_backup
    end
    @remote_bucket = "#{ENV['USER']}-s5-test"
    @sync ||= S5::Sync.new(remote_bucket: @remote_bucket)
  end

  def teardown
    if File.exists?(@encrypt_key_path_backup)
      FileUtils.mv @encrypt_key_path_backup, @encrypt_key_path
    end
    bucket = AWS.s3.buckets[@remote_bucket]
    bucket.objects.delete_all if bucket.exists?
    FileUtils.rm_rf fixtures_path.to_s
  end

  def test_encrypt_key_path
    assert_equal ENV['HOME'] + '/.s5.key', S5::Sync.encrypt_key_path
  end

  module SyncPutGetTest
    def test_sync_put_get
      s3_object = @sync.put(@path)
      assert_equal @plain, s3_object.read
      FileUtils.rm_rf(File.dirname(@path))
      @sync.get(@path)
      assert_equal @plain, File.read(@path)
    end

    def test_sync_put_with_encrypt
      @sync.encrypt!
      assert File.exists?(S5::Sync.encrypt_key_path)
      s3_object = @sync.put(@path)
      refute_equal @plain, s3_object.read
      assert_equal @plain, s3_object.read(encryption_key: File.binread(@encrypt_key_path))
      FileUtils.rm_rf(File.dirname(@path))
      @sync.get(@path)
      assert_equal @plain, File.binread(@path)
    end
  end

  class SinglePathTest < self
    include SyncPutGetTest
    def setup
      super
      @plain = Digest::SHA2.hexdigest(Time.now.to_f.to_s) + 'test'
      @path = fixtures_path.join('test.txt')
      File.open(@path, 'w') do |f|
        f.write @plain
      end
    end

    def test_default_remote_bucket
      assert_match '-s5sync', S5::Sync.new.remote_bucket
    end
  end

  class RelativePathTest < self
    include SyncPutGetTest
    def setup
      super
      @plain = Digest::SHA2.hexdigest(Time.now.to_f.to_s) + 'test'
      @key = 'fixtures/test.txt'
      basedir = File.expand_path('../../', __FILE__)
      @sync = S5::Sync.new(local_path: basedir, remote_bucket: @remote_bucket)
      @path = basedir + '/' + @key
      FileUtils.mkdir_p File.dirname(@path)
      File.open(@path, 'w') do |f|
        f.write @plain
      end
    end

    def test_object_path
      s3_object = @sync.put(@key)
      assert_equal @key, s3_object.key
      FileUtils.rm_rf(File.dirname(@path))
      @sync.get(@key)
      assert_equal @plain, File.binread(@path)
    end

    def test_delete
      @sync.put(@key)
      s3_object = @sync.delete(@key)
      assert_raises AWS::S3::Errors::NoSuchKey do
        s3_object.read
      end
    end
  end
end
