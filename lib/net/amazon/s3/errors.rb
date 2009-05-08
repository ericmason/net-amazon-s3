module Net; module Amazon; class S3; class S3Error < StandardError

  class AccessDenied < S3Error; end
  class AccountProblem < S3Error; end
  class AllAccessDisabled < S3Error; end
  class AmbiguousGrantByEmailAddress < S3Error; end
  class OperationAborted < S3Error; end
  class BadDigest < S3Error; end
  class BucketAlreadyExists < S3Error; end
  class BucketNotEmpty < S3Error; end
  class CredentialsNotSupported < S3Error; end
  class EntityTooLarge < S3Error; end
  class IncompleteBody < S3Error; end
  class InternalError < S3Error; end
  class InvalidAccessKeyId < S3Error; end
  class InvalidAddressingHeader < S3Error; end
  class InvalidArgument < S3Error; end
  class InvalidBucketName < S3Error; end
  class InvalidDigest < S3Error; end
  class InvalidRange < S3Error; end
  class InvalidSecurity < S3Error; end
  class InvalidStorageClass < S3Error; end
  class InvalidTargetBucketForLogging < S3Error; end
  class KeyTooLong < S3Error; end
  class InvalidURI < S3Error; end
  class MalformedACLError < S3Error; end
  class MalformedXMLError < S3Error; end
  class MaxMessageLengthExceeded < S3Error; end
  class MetadataTooLarge < S3Error; end
  class MethodNotAllowed < S3Error; end
  class MissingContentLength < S3Error; end
  class MissingSecurityHeader < S3Error; end
  class NoLoggingStatusForKey < S3Error; end
  class NoSuchBucket < S3Error; end
  class NoSuchKey < S3Error; end
  class NotImplemented < S3Error; end
  class NotSignedUp < S3Error; end
  class PreconditionFailed < S3Error; end
  class RequestTimeout < S3Error; end
  class RequestTimeTooSkewed < S3Error; end
  class RequestTorrentOfBucketError < S3Error; end
  class SignatureDoesNotMatch < S3Error; end
  class TooManyBuckets < S3Error; end
  class UnexpectedContent < S3Error; end
  class UnresolvableGrantByEmailAddress < S3Error; end

end; end; end; end
