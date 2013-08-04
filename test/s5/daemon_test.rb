require 'test_helper'

class S5::DaemonTest < MiniTest::Test
  class DaemonFiber < S5::Daemon
    attr_accessor :fiber
    def observe
      @fiber = Fiber.new do
        super
      end
    end

    def create_or_update(*args)
      proc = super
      ->(base, relative){
        proc.call(base, relative).tap{
          Fiber.yield
        }
      }
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

  def test_touch_new_file
    @daemon.observe
    fork do
      sleep 0.1
      FileUtils.touch @path
    end
    @daemon.fiber.resume
    assert true, AWS.s3.buckets[@bucket_name].objects[File.basename(@path)].exists?
  end
end
