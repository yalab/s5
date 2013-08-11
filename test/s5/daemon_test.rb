require 'test_helper'

class S5::DaemonTest < S5::Test
  class DaemonFiber < S5::Daemon
    attr_accessor :fiber
    def observe
      @fiber = Fiber.new do
        super
      end
    end

    %w(create_or_update delete).each do |name|
      module_eval <<-METHOD, __FILE__, __LINE__
        def #{name}(*args)
          proc = super
          ->(base, relative){
            proc.call(base, relative).tap{
              Fiber.yield
            }
          }
        end
      METHOD
    end

    def resume
      @fiber.resume
    end
  end

  def setup
    super
    @bucket_name = "#{ENV["USER"]}-s5-daemon-test"
    @daemon = DaemonFiber.new(@fixtures_path, bucket_name: @bucket_name)
    @path = @fixtures_path.join(Time.now.to_f.to_s)
  end

  def teardown
    super
    bucket.delete! if bucket.exists? && bucket.versioned?
  end

  def test_sync_when_initialize
    sync = S5::Sync.new(local_path: @fixtures_path,
                        remote_bucket: @bucket_name)
    assert_equal sync.remote_list.keys.sort, sync.local_list.keys.sort
  end

  def test_touch_new_file_and_delete
    @daemon.observe
    user_context{ FileUtils.touch @path }
    @daemon.resume
    key = File.basename(@path)
    assert true, s3_object(key).exists?

    user_context{ FileUtils.rm_rf(@path) }
    @daemon.resume
    assert_raises AWS::S3::Errors::NoSuchKey do
      s3_object(key).read
    end
  end

  private
  def user_context
    fork do
      sleep 0.1
      yield
    end
  end

  def s3_object(key)
    bucket.objects[key]
  end

  def bucket
    AWS.s3.buckets[@bucket_name]
  end
end
