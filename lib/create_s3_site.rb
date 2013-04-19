require 'mharris_ext'
require 'aws-sdk'

module CreateS3Site
  class Bucket
    include FromHash
    attr_accessor :name, :bucket
    fattr(:s3) do
      AWS::S3.new
    end

    def create!
      @bucket ||= s3.buckets.create(name, :acl => :public_read)
    end

    def configure_hosting!
      bucket.configure_website do |cfg|
        cfg.index_document_suffix = 'index.html'
        cfg.error_document_key = 'error.html'
      end

      policy = AWS::S3::Policy.new
      policy.allow(
        :actions => ["s3:GetObject"],
        :resources => "arn:aws:s3:::#{name}/*",
        :principals => :any)

      bucket.policy = policy
    end

    def setup!
      puts "doing #{name}"
      create!
      configure_hosting!
    end

    def upload!(path)
      Dir["#{path}/**/*"].select { |x| FileTest.file?(x) }.each do |file|
        short = file.gsub("#{path}/","")
        data = File.read(file)
        bucket.objects[short].write(data)
      end
    end

    class << self
      def get(name)
        res = new(:name => name)
        res.setup!
        res
      end
      def upload!(name,path)
        get(name).upload!(path)
      end
    end
  end
end

#CreateS3Site::Bucket.upload! "emberexamples999", "/code/orig/create_s3_site/public"


