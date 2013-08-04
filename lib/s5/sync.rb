class S5::Sync
  attr_reader :bucket_name

  def self.encrypt_key_path
    ENV['HOME'] + '/.s5.key'
  end

  def initialize(basedir=nil, bucket_name: nil)
    @basedir = basedir
    @bucket_name = bucket_name || AWS.iam.users.first.name + '-s5sync'
    @options = {}
  end

  def delete(key)
    (path, s3_key) = generate_path_and_key(key)
    s3_object(s3_key).tap{|o| o.delete }
  end

  def encrypt!
    key_path = self.class.encrypt_key_path
    unless File.exists?(key_path)
      File.open(key_path, 'w:BINARY', 0600) do |f|
        f.write OpenSSL::Cipher::AES256.new(:CBC).random_key
      end
    end
    @options[:server_side_encryption] = :aes256
    @options[:encryption_key] = File.binread(key_path)
  end

  def get(key)
    (path, s3_key) = generate_path_and_key(key)
    FileUtils.mkdir_p(File.dirname(path))
    File.open(path, 'wb') do |f|
      f.write s3_object(s3_key).read(@options)
    end
  end

  def local_list
    raise unless @basedir
    offset = @basedir.length + 1
    Hash[Dir.glob(@basedir + '/**/*').to_a.map{|f|
           [f[offset..-1], File.mtime(f)]
         }]
  end

  def put(key)
    (path, s3_key) = generate_path_and_key(key)
    s3_object(s3_key).write(File.binread(path), @options)
  end

  def remote_list
    Hash[s3_objects.to_a.map do |object|
      [object.key, object.last_modified]
    end]
  end

  private
  def s3_bucket
    s3 = AWS.s3
    _bucket = s3.buckets[@bucket_name]
    if _bucket.exists?
      _bucket
    else
      s3.buckets.create(@bucket_name)
    end
  end

  def s3_object(key)
    s3_objects[key]
  end

  def s3_objects
    s3_bucket.objects
  end

  def generate_path_and_key(path)
    if Pathname.new(path).absolute?
      [path, File.basename(path)]
    else
      [File.join(@basedir, path), path]
    end
  end
end
