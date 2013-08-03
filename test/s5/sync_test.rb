require 'test_helper'

class S5::SyncTest < MiniTest::Unit::TestCase
  def setup
    @encrypt_key_path = S5::Sync.encrypt_key_path
    @encrypt_key_path_backup = @encrypt_key_path + '.s5_test'
    if File.exists?(@encrypt_key_path)
      FileUtils.mv @encrypt_key_path, @encrypt_key_path_backup
    end

    @plain = Digest::SHA2.hexdigest(Time.now.to_f.to_s) + 'test'
    @path = File.expand_path('../../fixtures/test.txt', __FILE__)
    FileUtils.mkdir_p File.dirname(@path)
    File.open(@path, 'w') do |f|
      f.write @plain
    end
    @sync = S5::Sync.new(@path)
  end

  def teardown
    if File.exists?(@encrypt_key_path_backup)
      FileUtils.mv @encrypt_key_path_backup, @encrypt_key_path
    end
  end

  def test_default_bucket_name
    assert_match '-s5sync', @sync.bucket
  end

  def test_sync_run
    s3_object = @sync.run
    assert_equal @plain, s3_object.read
  end

  def test_encrypt_key_path
    assert_equal ENV['HOME'] + '/.s5.key', S5::Sync.encrypt_key_path
  end

  def test_sync_run_with_encrypt
    @sync.encrypt!
    assert File.exists?(S5::Sync.encrypt_key_path)
    s3_object = @sync.run
    refute_equal @plain, s3_object.read
    assert_equal @plain, s3_object.read(encryption_key: File.binread(@encrypt_key_path))
  end
end
