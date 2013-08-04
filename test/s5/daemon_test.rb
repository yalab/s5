require 'test_helper'

class S5::DaemonTest < MiniTest::Test
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
    @fixture_dir = File.expand_path('../../fixtures', __FILE__)
    @bucket_name = "#{ENV["USER"]}-s5-daemon-test"
    @daemon = DaemonFiber.new(@fixture_dir, bucket_name: @bucket_name)
    @path = @fixture_dir + '/' + Time.now.to_f.to_s
  end

  def teardown
    if File.exists?(@path)
      File.unlink(@path)
    end
  end

  def test_touch_new_file_and_delete
    @daemon.observe
    user_context{ FileUtils.touch @path }
    @daemon.resume
    key = File.basename(@path)
    assert true, s3_object(@bucket_name, key).exists?

    user_context{ FileUtils.rm_rf(@path) }
    @daemon.resume
    assert_raises AWS::S3::Errors::NoSuchKey do
      s3_object(@bucket_name, key).read
    end
  end

  private
  def user_context
    fork do
      sleep 0.1
      yield
    end
  end

  def s3_object(bucket_name, key)
    AWS.s3.buckets[bucket_name].objects[key]
  end
end
