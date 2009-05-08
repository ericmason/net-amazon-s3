require 'rexml/document'
require 'time'
require 'uri'

module Net; module Amazon; class S3

  # Represents an Amazon S3 bucket. This class should only be instantiated
  # through one of the methods in the S3 class.
  class Bucket
    include Comparable
    include Enumerable
  
    attr_reader :name, :creation_date
  
    # Creates and returns a new Bucket object. You should never create new
    # Bucket objects directly. Instead, use one of the methods in the S3 class.
    def initialize(s3, bucket_name, creation_date)
      @s3            = s3
      @name          = bucket_name
      @creation_date = creation_date

      @cache = {}
    end
    
    # Compares two buckets by name.
    def <=>(bucket)
      return @name <=> bucket.name
    end
    
    # Creates and returns a new S3::Object with the specified +object_key+ and
    # +value+. If this bucket already contains an object with the specified key,
    # that object will be overwritten.
    # 
    # If +value+ is an open IO stream, the value of the object will be read from
    # the stream.
    def create_object(object_key, value, metadata = {})
      object_key_escaped = S3::Object.escape_key(object_key)
      
      headers = {}
      metadata.each {|key, value| headers["x-amz-meta-#{key}"] = value }
      
      response = @s3.request_put("/#{@name}/#{object_key_escaped}", value,
          headers)
      @s3.error?(response)

      @cache.delete(:objects)

      return get_object(object_key)
    end
    
    alias []= create_object

    # Deletes the specified object from this bucket.
    def delete_object(object_key)
      object_key_escaped = S3::Object.escape_key(object_key)
    
      unless object = get_object(object_key)
        raise S3Error::NoSuchKey, 'The specified key does not exist'
      end
      
      @cache.delete(:objects)
      
      return true unless @s3.error?(@s3.request_delete(
          "/#{@name}/#{object_key_escaped}"))
    end
    
    # Iterates through the list of objects.
    def each
      get_objects.each {|key, value| yield key, value }
    end
  
    # Returns a S3::Object representing the specified +object_key+, or +nil+ if
    # the object doesn't exist in this bucket.
    def get_object(object_key)
      return get_objects(object_key)[object_key]
    end
    
    alias [] get_object

    # Gets a list of all objects in this bucket whose keys begin with +prefix+.
    # Returns a Hash of S3::Object objects indexed by object key.
    def get_objects(prefix = '')
      prefix = prefix.toutf8
    
      if @s3.options[:enable_cache] && !@cache[:objects].nil? &&
          !@cache[:objects][prefix].nil?
        return @cache[:objects][prefix]
      end
      
      if @cache[:objects].nil?
        @cache[:objects] = {}
      end
      
      objects      = {}
      request_uri  = "/#{@name}?prefix=#{URI.escape(prefix)}"
      is_truncated = true
      
      # The request is made in a loop because the S3 API limits results to pages
      # of 1,000 objects by default, so if there are more than 1,000 objects,
      # we'll have to send more requests to get them all.
      while is_truncated do
        response = @s3.request_get(request_uri)
        @s3.error?(response)
        
        xml = REXML::Document.new(response.body)
        
        if xml.root.elements['IsTruncated'].text == 'false'
          is_truncated = false
        else
          request_uri = "/#{@name}?prefix=#{URI.escape(prefix)}&marker=" +
              xml.root.elements.to_a('Contents').last.elements['Key'].text
        end
        
        next if xml.root.elements['Contents'].nil?
  
        xml.root.elements.each('Contents') do |element|
          object_key           = element.elements['Key'].text
          object_size          = element.elements['Size'].text
          object_etag          = element.elements['ETag'].text
          object_last_modified = Time.parse(
              element.elements['LastModified'].text)
          
          objects[object_key] = S3::Object.new(@s3, self, object_key,
              object_size, object_etag, object_last_modified)
        end
      end

      return @cache[:objects][prefix] = objects
    end
    
    # Returns +true+ if an object with the specified +object_key+ exists in
    # this bucket, +false+ otherwise.
    def object_exist?(object_key)
      return get_objects.has_key?(object_key)
    end
    
    alias has_object? object_exist?

  end
  
end; end; end
