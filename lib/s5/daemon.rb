require 'fssm'

class S5::Daemon
  def initialize(*paths, bucket_name: nil)
    @syncs = paths.map{|path|
      sync = S5::Sync.new(path, bucket_name: bucket_name)
      sync.encrypt!
      [path, sync]
    }
  end

  def start
    @pid = fork do
      observe
    end
  end

  def stop
    Process.kill :QUIT, @pid
  end

  def observe
    observers = @syncs.map!{|path, sync|
      [path, create_or_update(sync), delete(sync)]
    }
    FSSM.monitor do
      observers.each do |_, create_or_update, delete_proc|
        path _ do
          glob '**/*'
          create &create_or_update
          update &create_or_update
          delete &delete_proc
        end
      end
    end
  end

  private
  def create_or_update(sync)
    ->(base, relative){
      sync.put(relative)
    }
  end

  def delete(sync)
    ->(base, relative){
      sync.delete(relative)
    }
  end
end
