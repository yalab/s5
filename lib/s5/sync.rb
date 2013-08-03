class S5::Sync
  attr_reader :bucket_name

  def self.encrypt_key_path
    ENV['HOME'] + '/.s5.key'
  end

  def initialize(relative, basedir=nil, bucket_name: nil)
    (@path, @key) = if basedir
                     [basedir + '/'  + relative, relative]
                   else
                     [relative, File.basename(relative)]
                   end
    @bucket_name = if bucket_name
                     bucket_name
                   else
                     AWS.iam.users.first.name + '-s5sync'
                   end
    @options = {}
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

  def put
    s3_object(@key).write(File.binread(@path), @options)
  end

  private
  def bucket
    s3 = AWS.s3
    _bucket = s3.buckets[@bucket_name]
    if _bucket.exists?
      _bucket
    else
      s3.buckets.create(@bucket_name)
    end
  end

  def s3_object(key)
    bucket.objects[key]
  end
end
