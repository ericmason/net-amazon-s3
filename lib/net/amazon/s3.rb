require 'base64'
require 'digest/md5'
require 'net/https'
require 'net/amazon/s3/bucket'
require 'net/amazon/s3/errors'
require 'net/amazon/s3/object'
require 'openssl'
require 'rexml/document'

module Net; module Amazon

  # = Net::Amazon::S3
  # 
  # This library implements the Amazon S3 REST API (Rubyfied for your pleasure).
  # Its usage is hopefully pretty straightforward. See below for examples.
  # 
  # Author::    Ryan Grove (mailto:ryan@wonko.com)
  # Version::   0.1.0
  # Copyright:: Copyright (c) 2006 Ryan Grove. All rights reserved.
  # License::   New BSD License (http://opensource.org/licenses/bsd-license.php)
  # Website::   http://wonko.com/software/net-amazon-s3
  # 
  # == A Brief Overview of Amazon S3
  # 
  # Amazon S3 stores arbitrary values (objects) identified by keys and organized
  # into buckets. An S3 bucket is essentially a glorified Hash. Object values
  # can be up to 5 GB in size, and objects can also have up to 2 KB of metadata
  # associated with them.
  # 
  # Bucket names share a global namespace and must be unique across all of
  # S3, but object keys only have to be unique within the bucket in which they
  # are stored.
  # 
  # For more details, visit http://s3.amazonaws.com
  # 
  # == Installation
  # 
  #   gem install net-amazon-s3
  # 
  # == Examples
  # 
  # === Create an instance of the S3 client
  # 
  #   require 'rubygems'
  #   require 'net/amazon/s3'
  #   
  #   access_key_id     = 'DXM37ARQ25519H34E6W2'
  #   secret_access_key = '43HM88c+8kYr/UeFp+shjTnzFgisO5AZzpEO06FU'
  #   
  #   s3 = Net::Amazon::S3.new(access_key_id, secret_access_key)
  #   
  # === Create a bucket and add an object to it
  # 
  #   foo = s3.create_bucket('foo')
  #   foo['bar'] = 'baz'            # create object 'bar' and assign it the
  #                                 # value 'baz'
  # 
  # === Upload a large file to the bucket
  # 
  #   File.open('mybigmovie.avi', 'rb') do |file|
  #     foo['mybigmovie.avi'] = file
  #   end
  # 
  # === Download a large file from the bucket
  # 
  #   File.open('mybigmovie.avi', 'wb') do |file|
  #     foo['mybigmovie.avi'].value {|chunk| file.write(chunk) }
  #   end
  # 
  # === Get a hash containing all objects in the bucket
  # 
  #   objects = foo.get_objects
  # 
  # === Get all objects in the bucket whose keys begin with "my"
  # 
  #   my_objects = foo.get_objects('my')
  # 
  # === Delete the bucket and everything in it
  # 
  #   s3.delete_bucket('foo', true)
  # 
  # == TODO
  # 
  # * Object metadata support
  # * ACLs
  # * Logging configuration
  # * Unit tests
  # 
  class S3
    include Enumerable
    
    REST_ENDPOINT = 's3.amazonaws.com'
  
    attr_accessor :access_key_id, :secret_access_key
    attr_reader   :options
    
    # Creates and returns a new S3 client. The following options are available:
    # 
    # [<tt>:enable_cache</tt>] Set to +true+ to enable intelligent caching of
    #                          frequently-used requests. This can improve
    #                          performance, but may result in staleness if other
    #                          clients are simultaneously modifying the buckets
    #                          and objects in this S3 account. Default is
    #                          +true+.
    # [<tt>:ssl</tt>] Set to +true+ to use SSL for all requests. No verification
    #                 is performed on the server's certificate when SSL is used.
    #                 Default is +true+.
    def initialize(access_key_id, secret_access_key, options = {})
      @access_key_id     = access_key_id
      @secret_access_key = secret_access_key

      @options = {
        :enable_cache => true,
        :ssl          => true
      }

      @options.merge!(options)
      
      @cache = {}
    end
    
    # Returns +true+ if a bucket with the specified +bucket_name+ exists in this
    # S3 account, +false+ otherwise.
    def bucket_exist?(bucket_name)
      return get_buckets.has_key?(bucket_name)
    end
    
    alias has_bucket? bucket_exist?

    # Creates a new bucket with the specified +bucket_name+ and returns a
    # Bucket object representing it.
    def create_bucket(bucket_name)
      error?(request_put("/#{bucket_name}"))
      @cache.delete(:buckets)
      return get_bucket(bucket_name)
    end

    # Deletes the bucket with the specified +bucket_name+. If +recursive+ is
    # +true+, all objects contained in the bucket will also be deleted. If
    # +recursive+ is +false+ and the bucket is not empty, a
    # S3Error::BucketNotEmpty error will be raised.
    def delete_bucket(bucket_name, recursive = false)
      unless bucket = get_bucket(bucket_name)
        raise S3Error::NoSuchBucket, 'The specified bucket does not exist'
      end
    
      if recursive
        bucket.each {|object| bucket.delete_object(object.name) }
      end
      
      @cache.delete(:buckets)
      
      return true unless error?(request_delete("/#{bucket_name}"))
    end

    # Iterates through the list of buckets.
    def each
      get_buckets.each {|key, value| yield key, value }
    end

    # Raises the appropriate error if the specified Net::HTTPResponse object
    # contains an Amazon S3 error; returns +false+ otherwise.
    def error?(response)
      return false if response.is_a?(Net::HTTPSuccess)

      xml = REXML::Document.new(response.body)
      
      unless xml.root.name == 'Error'
        raise S3Error, "Unknown error: #{response.body}"
      end
      
      error_code    = xml.root.elements['Code'].text
      error_message = xml.root.elements['Message'].text

      if S3Error.const_defined?(error_code)
        raise S3Error.const_get(error_code), error_message
      else
        raise S3Error, "#{error_code}: #{error_message}"
      end
    end

    # Returns a Bucket object representing the specified bucket, or +nil+ if the
    # bucket doesn't exist.
    def get_bucket(bucket_name)
      return nil unless bucket_exist?(bucket_name)
      return @cache[:buckets][bucket_name]
    end
    
    alias [] get_bucket

    # Gets a list of all buckets owned by this account. Returns a Hash of
    # Bucket objects indexed by bucket name.
    def get_buckets
      if @options[:enable_cache] && !@cache[:buckets].nil?
        return @cache[:buckets]
      end
      
      response = request_get('/')
      error?(response)
      
      xml = REXML::Document.new(response.body)
      
      buckets = {}

      xml.root.elements.each('Buckets/Bucket') do |element|
        bucket_name   = element.elements['Name'].text
        creation_date = Time.parse(element.elements['CreationDate'].text)
        
        buckets[bucket_name] = Bucket.new(self, bucket_name, creation_date)
      end
      
      return @cache[:buckets] = buckets
    end
    
    # Sends a properly-signed DELETE request to the specified S3 path and
    # returns a Net::HTTPResponse object.
    def request_delete(path, headers = {})
      http = Net::HTTP.new(REST_ENDPOINT, @options[:ssl] ? 443 : 80)

      http.use_ssl     = @options[:ssl]
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      
      http.start do |http|
        req = sign_request(Net::HTTP::Delete.new(path), nil, headers)
        return http.request(req)
      end
    end
    
    # Sends a properly-signed GET request to the specified S3 path and returns
    # a Net::HTTPResponse object.
    # 
    # When called with a block, yields a Net::HTTPResponse object whose body has
    # not been read; the caller can process it using
    # Net::HTTPResponse.read_body.
    def request_get(path, headers = {})
      http = Net::HTTP.new(REST_ENDPOINT, @options[:ssl] ? 443 : 80)

      http.use_ssl     = @options[:ssl]
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      
      http.start do |http|
        req = sign_request(Net::HTTP::Get.new(path), nil, headers)
        
        if block_given?
          http.request(req) {|response| yield response }
        else
          return http.request(req)
        end
      end
    end
    
    # Sends a properly-signed HEAD request to the specified S3 path and returns
    # a Net::HTTPResponse object.
    def request_head(path, headers = {})
      http = Net::HTTP.new(REST_ENDPOINT, @options[:ssl] ? 443 : 80)

      http.use_ssl     = @options[:ssl]
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      
      http.start do |http|
        req = sign_request(Net::HTTP::Head.new(path), nil, headers)
        return http.request(req)
      end
    end
    
    # Sends a properly-signed PUT request to the specified S3 path and returns a
    # Net::HTTPResponse object.
    # 
    # If +content+ is an open IO stream, the body of the request will be read
    # from the stream.
    def request_put(path, content = nil, headers = {})
      http = Net::HTTP.new(REST_ENDPOINT, @options[:ssl] ? 443 : 80)
      
      http.use_ssl     = @options[:ssl]
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      
      http.start do |http|
        req = sign_request(Net::HTTP::Put.new(path), content, headers)
        
        if content.is_a?(IO)
          req.body_stream = content
        else
          req.body = content
        end
        
        response = http.request(req)
        
        return response
      end
    end
    
    private
    
    # Adds an appropriately-signed +Authorization+ header to the
    # Net::HTTPRequest +request+.
    # 
    # If +content+ is an open IO stream, the body of the request will be read
    # from the stream.
    def sign_request(request, content = nil, headers = {})
      unless request.is_a?(Net::HTTPRequest)
        raise ArgumentError,
            "Expected Net::HTTPRequest, not #{request.class}"
      end

      unless request.path =~ /^(\/.*?)(?:\?.*)?$/i
        raise S3Error, "Invalid request path: #{request.path}"
      end
      
      path = $1
      
      request['Host'] = REST_ENDPOINT
      request['Date'] = Time.new.httpdate()
      
      if content.nil?
        request['Content-Length'] = 0
      elsif content.is_a?(IO)
        # Generate an MD5 hash of the stream's contents.
        md5 = Digest::MD5.new
        content.rewind
        
        while buffer = content.read(65536) do
          md5 << buffer
        end
        
        content.rewind
        
        # Set headers.
        request['Content-Type']   = 'binary/octet-stream'
        request['Content-Length'] = content.stat.size
        request['Content-MD5']    = Base64.encode64(md5.digest).strip
      else
        request['Content-Type']   = 'binary/octet-stream'
        request['Content-Length'] = content.length
        request['Content-MD5']    = Base64.encode64(Digest::MD5.digest(
            content)).strip
      end

      headers.each {|key, value| request[key] = value }
      
      hmac = OpenSSL::HMAC.new(@secret_access_key, OpenSSL::Digest::SHA1.new)
      hmac << "#{request.method}\n#{request['Content-MD5']}\n".toutf8 +
          "#{request['Content-Type']}\n#{request['Date']}\n".toutf8
      
      request.to_hash.keys.sort.each do |key|
        if key =~ /^x-amz-/i
          hmac << "#{key.downcase.strip}:#{request[key].strip}\n".toutf8
        end
      end
      
      hmac << path.toutf8
      
      signature = Base64.encode64(hmac.digest).strip
      
      request['Authorization'] = "AWS #{@access_key_id}:#{signature}"
      
      return request
    end

  end

end; end
