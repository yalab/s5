class S5::Sync
  attr_reader :bucket
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
  end

  def run
    @s3_object.write(File.read(@path))
  end
end
