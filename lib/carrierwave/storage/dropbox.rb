# encoding: utf-8
begin
  require 'dropbox_sdk'
rescue LoadError
  raise "You don't have the dropbox-sdk gem installed." 
end

module CarrierWave
  module Storage

    ##
    # Uploads things to Amazon S3 using the "fog" gem.
    # You'll need to specify the access_key_id, secret_access_key and bucket.
    #
    #     Dropbox.configure do |config|
    #       config.dropbox_access_key_id = "xxxxxx"
    #       config.dropbox_secret_access_key = "xxxxxx"
    #       config.dropbox_bucket = "my_bucket_name"
    #     end
    #
    # You can set the access policy for the uploaded files:
    #
    #     CarrierWave.configure do |config|
    #       config.s3_access_policy = :public_read
    #     end
    #
    # The default is :public_read. For more options see:
    #
    # http://docs.amazonwebservices.com/AmazonS3/latest/RESTAccessPolicy.html#RESTCannedAccessPolicies
    #
    # The following access policies are available:
    #
    # [:private]              No one else has any access rights.
    # [:public_read]          The anonymous principal is granted READ access.
    #                         If this policy is used on an object, it can be read from a
    #                         browser with no authentication.
    # [:public_read_write]    The anonymous principal is granted READ and WRITE access.
    # [:authenticated_read]   Any principal authenticated as a registered Amazon S3 user
    #                         is granted READ access.
    #
    # You can change the generated url to a cnamed domain by setting the cnamed config:
    #
    #     CarrierWave.configure do |config|
    #       config.s3_cnamed = true
    #       config.s3_bucket = 'bucketname.domain.tld'
    #     end
    #
    # Now the resulting url will be
    #
    #     http://bucketname.domain.tld/path/to/file
    #
    # instead of
    #
    #     http://bucketname.domain.tld.s3.amazonaws.com/path/to/file
    #
    # You can specify a region. US Standard "us-east-1" is the default.
    #
    #     CarrierWave.configure do |config|
    #       config.s3_region = 'eu-west-1'
    #     end
    #
    # Available options are defined in Fog Storage[http://github.com/geemus/fog/blob/master/lib/fog/aws/storage.rb]
    #
    #     'eu-west-1' => 's3-eu-west-1.amazonaws.com'
    #     'us-east-1' => 's3.amazonaws.com'
    #     'ap-southeast-1' => 's3-ap-southeast-1.amazonaws.com'
    #     'us-west-1' => 's3-us-west-1.amazonaws.com'
    #
    class Dropbox < Abstract
      class File

        def initialize(uploader, base, path)
          @base = base
          @path = path
          @uploader = uploader
        end

        ##
        # Returns the current path of the file on S3
        #
        # === Returns
        #
        # [String] A path
        #
        def path
          @path
        end

        ##
        # Reads the contents of the file from S3
        #
        # === Returns
        #
        # [String] contents of the file
        #
        def read
          @client.get_file(path)
        end

        ##
        # Remove the file from Amazon S3
        #
        def delete
          @client.file_delete(path)
        end

        ##
        # Returns the url on Amazon's S3 service
        #
        # === Returns
        #
        # [String] file's url
        #
        def url
          response = @client.media(path)
          response[:url]
        end


        def store(file)
          client.put_file(path, file.read)
        end

        def client
          @base.client
        end
      end

      def store!(file)
        f = CarrierWave::Storage::Dropbox::File.new(uploader, self, uploader.store_path)
        f.store(file)
        f
      end

      def retrieve!
        f = CarrierWave::Storage::Dropbox::File.new(uploader, self, uploader.store_path)
        f.read(file)
        f
      end

      def client
        @client ||= DropboxClient.new(session, uploader.dropbox_access_type)
        puts "linked account: ",  @client.account_info().inspect
      end

      def session
        @session ||= new_session
      end

      def new_session
        db_session = DropboxSession.new(uploader.dropbox_consumer_key, uploader.dropbox_consumer_secret)
        #db_session.set_access_token(@dropbox_token, @dropbox_token_secret)
        db_session.get_access_token
      end

      def set_access_token(dropbox_token, dropbox_token_secret)
        @dropbox_token = dropbox_token
        @dropbox_token_secret = dropbox_token_secret
      end
    end # Dropbox
  end # Storage
end # CarrierWave

