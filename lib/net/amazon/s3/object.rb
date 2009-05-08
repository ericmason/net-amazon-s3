module Net; module Amazon; class S3

  # Represents an Amazon S3 object. This class should only be instantiated
  # through one of the methods in Bucket.
  class Object
    include Comparable
  
    #--
    # Public Class Methods
    #++
    
    # Escapes an object key for use in an S3 request path. This method should
    # not be used to escape object keys for use in URL query parameters. Use
    # URI.escape for that.
    def self.escape_key(object_key)
      return object_key.gsub(' ', '+').toutf8
    end
    
    #--
    # Public Instance Methods
    #++

    attr_reader :name, :size, :etag, :last_modified
    
    def initialize(s3, bucket, object_key, size, etag, last_modified)
      @s3            = s3
      @bucket        = bucket
      @key           = object_key.toutf8
      @size          = size
      @etag          = etag
      @last_modified = last_modified
      
      @cache = {}
    end
    
    # Compares two objects by key.
    def <=>(object)
      return @key <=> object.key
    end
    
    # Gets this object's value.
    # 
    # When called with a block, yields the value in chunks as it is read in from
    # the socket.
    def value
      key_escaped = Object.escape_key(@key)
      
      if block_given?
        @s3.request_get("/#{@bucket.name}/#{key_escaped}") do |response|
          @s3.error?(response)
          response.read_body {|chunk| yield chunk }
        end
      else
        response = @s3.request_get("/#{@bucket.name}/#{key_escaped}")
        @s3.error?(response)
        
        return response.body
      end
    end
    
    # Sets this object's value.
    # 
    # If +new_value+ is an open IO stream, the value will be read from the
    # stream.
    def value=(new_value)
      key_escaped = Object.escape_key(@key)

      response = @s3.request_put("/#{@bucket.name}/" +
          "#{key_escaped}", new_value)
      @s3.error?(response)
      
      return new_value
    end
    
  end
  
end; end; end
