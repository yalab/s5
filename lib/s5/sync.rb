class S5::Sync
  attr_reader :bucket

  def self.encrypt_key_path
    ENV['HOME'] + '/.s5.key'
  end

  def initialize(path, bucket: nil)
    @path = path
    @bucket = if bucket
                bucket
              else
                AWS.iam.users.first.name + '-s5sync'
              end
    s3 = AWS.s3
    bucket = s3.buckets[@bucket]
    unless bucket.exists?
      bucket = s3.buckets.create(@bucket)
    end
    @s3_object = bucket.objects[File.basename(@path)]
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

  def run
    @s3_object.write(File.binread(@path), @options)
  end
end
