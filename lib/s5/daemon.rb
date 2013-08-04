require 'fssm'

class S5::Daemon
  def initialize(*paths, bucket_name: nil)
    @syncs = paths.map{|path| [path, S5::Sync.new(path, bucket_name: bucket_name)] }
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
      [path, create_or_update(sync)]
    }
    FSSM.monitor do
      observers.each do |_, create_or_update|
        path _ do
          glob '**/*'
          create &create_or_update
          update &create_or_update
        end
      end
    end
  end

  private
  def create_or_update(sync)
    ->(base, relative){
      sync.encrypt!
      sync.put(relative)
    }
  end
end
